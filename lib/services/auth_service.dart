import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'local_data_service.dart';
import 'gamification_service.dart';

/// Thrown when someone tries to log into an account that has been
/// deactivated from the "Manage Accounts" screen.
class AccountDeactivatedException implements Exception {
  final String message;
  AccountDeactivatedException([
    this.message =
        'This account has been deactivated. Ask to reactivate it from Manage Accounts, or use another account.',
  ]);

  @override
  String toString() => message;
}

/// One entry in the on-device list of accounts that have signed up / logged
/// in on this phone. This powers the "Manage Accounts" screen so the user
/// can see every account they've created and delete / deactivate / activate
/// it, without needing a backend admin panel.
class DeviceAccount {
  final String uid;
  final String email;
  final String name;
  final String status; // 'active' or 'inactive'

  DeviceAccount({
    required this.uid,
    required this.email,
    required this.name,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'status': status,
      };

  factory DeviceAccount.fromMap(Map<String, dynamic> m) => DeviceAccount(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        name: m['name'] ?? '',
        status: m['status'] ?? 'active',
      );

  DeviceAccount copyWith({String? name, String? status}) => DeviceAccount(
        uid: uid,
        email: email,
        name: name ?? this.name,
        status: status ?? this.status,
      );
}

class AuthService {
  static const _deviceAccountsKey = 'device_accounts';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------
  // Sign up / sign in / sign out
  // ---------------------------------------------------------------------

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential;
  }

  /// Call this right after the student profile document has been created in
  /// Firestore (signup_screen.dart does this), so the new account shows up
  /// in "Manage Accounts" with its real name.
  Future<void> registerNewAccountOnDevice({
    required String uid,
    required String email,
    required String name,
  }) async {
    await _upsertDeviceAccount(
      DeviceAccount(uid: uid, email: email.trim(), name: name, status: 'active'),
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Check whether this account has been deactivated from Manage Accounts.
    final doc = await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .get();
    final status = (doc.data()?['status'] as String?) ?? 'active';

    if (status == 'inactive') {
      await _auth.signOut();
      throw AccountDeactivatedException();
    }

    // Keep the on-device account list up to date (name may have changed).
    await _upsertDeviceAccount(DeviceAccount(
      uid: uid,
      email: email.trim(),
      name: (doc.data()?['name'] as String?) ?? '',
      status: status,
    ));

    return credential;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No signed in user.');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------
  // Manage Accounts: list every account used on this device
  // ---------------------------------------------------------------------

  Future<List<DeviceAccount>> getDeviceAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deviceAccountsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => DeviceAccount.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _upsertDeviceAccount(DeviceAccount account) async {
    final accounts = await getDeviceAccounts();
    final i = accounts.indexWhere((a) => a.uid == account.uid);
    if (i >= 0) {
      accounts[i] = account;
    } else {
      accounts.add(account);
    }
    await _saveDeviceAccounts(accounts);
  }

  Future<void> _saveDeviceAccounts(List<DeviceAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _deviceAccountsKey,
      jsonEncode(accounts.map((a) => a.toMap()).toList()),
    );
  }

  /// Only removes the account from the on-device list shown in
  /// "Manage Accounts" — it does not touch Firebase.
  Future<void> forgetDeviceAccount(String uid) async {
    final accounts = await getDeviceAccounts();
    accounts.removeWhere((a) => a.uid == uid);
    await _saveDeviceAccounts(accounts);
  }

  /// Turn an account on/off. Because Firestore only allows an account to
  /// edit its own document, this briefly signs in as [email]/[password] to
  /// flip the status flag, then signs back out. The caller is returned to
  /// the login screen afterwards so the user can log into whichever
  /// account they want next.
  Future<void> setAccountStatus({
    required String email,
    required String password,
    required String status, // 'active' | 'inactive'
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .update({'status': status});

    final accounts = await getDeviceAccounts();
    final i = accounts.indexWhere((a) => a.uid == uid);
    if (i >= 0) accounts[i] = accounts[i].copyWith(status: status);
    await _saveDeviceAccounts(accounts);

    await _auth.signOut();
  }

  /// Permanently deletes an account: the Firebase Auth user, its Firestore
  /// profile, all locally-stored activity (tasks, quiz results, XP, etc.)
  /// and its entry in the on-device account list. Requires the account's
  /// own password because Firebase only lets a user delete their own
  /// login. The caller is returned to the login screen afterwards.
  Future<void> deleteAccountByPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    final uid = user.uid;

    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .delete();

    await LocalDataService().clearAllFor(uid);
    await GamificationService().clearAllFor(uid);
    await forgetDeviceAccount(uid);

    await user.delete();
  }
}
