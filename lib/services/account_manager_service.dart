import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ManagedAccount {
  final String uid;
  final String email;
  final String name;
  bool active; // local active flag
  final DateTime lastLogin;

  ManagedAccount({
    required this.uid,
    required this.email,
    required this.name,
    this.active = true,
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'active': active,
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory ManagedAccount.fromMap(Map<String, dynamic> m) => ManagedAccount(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        name: m['name'] ?? '',
        active: m['active'] ?? true,
        lastLogin: DateTime.tryParse(m['lastLogin'] ?? '') ?? DateTime.now(),
      );
}

/// Tracks accounts used on this device (does not store passwords).
class AccountManagerService {
  static final AccountManagerService _i = AccountManagerService._();
  factory AccountManagerService() => _i;
  AccountManagerService._();

  List<ManagedAccount> accounts = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('managed_accounts');
    if (raw == null) {
      accounts = [];
      return;
    }
    final list = jsonDecode(raw) as List;
    accounts = list
        .map((e) => ManagedAccount.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'managed_accounts',
      jsonEncode(accounts.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> upsert({
    required String uid,
    required String email,
    String name = '',
  }) async {
    await load();
    final i = accounts.indexWhere((a) => a.uid == uid);
    final entry = ManagedAccount(
      uid: uid,
      email: email,
      name: name.isNotEmpty
          ? name
          : (i >= 0 ? accounts[i].name : email.split('@').first),
      active: true,
      lastLogin: DateTime.now(),
    );
    if (i >= 0) {
      accounts[i] = entry;
    } else {
      accounts.insert(0, entry);
    }
    await _save();
  }

  Future<void> setActive(String uid, bool active) async {
    await load();
    final i = accounts.indexWhere((a) => a.uid == uid);
    if (i >= 0) {
      accounts[i] = ManagedAccount(
        uid: accounts[i].uid,
        email: accounts[i].email,
        name: accounts[i].name,
        active: active,
        lastLogin: accounts[i].lastLogin,
      );
      await _save();
    }
  }

  /// Removes account from this device list only (does not delete Firebase user).
  Future<void> removeFromDevice(String uid) async {
    await load();
    accounts.removeWhere((a) => a.uid == uid);
    await _save();
    // Wipe local activity for that uid
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains(uid)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
