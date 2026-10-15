import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/account_manager_service.dart';
import '../../services/auth_service.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';
import '../../services/study_materials_service.dart';
import 'login_screen.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final _mgr = AccountManagerService();
  final _auth = AuthService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _mgr.load();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleActive(ManagedAccount a) async {
    await _mgr.setActive(a.uid, !a.active);
    await _load();
  }

  Future<void> _delete(ManagedAccount a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          'Remove ${a.email} from this device?\n'
          'Local activity for this account will be deleted.\n'
          'You can still login later with email/password.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    final currentUid = _auth.currentUser?.uid;
    await _mgr.removeFromDevice(a.uid);

    if (currentUid == a.uid) {
      await _auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mgr.accounts.isEmpty
              ? const Center(child: Text('No accounts on this device yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mgr.accounts.length,
                  itemBuilder: (context, i) {
                    final a = _mgr.accounts[i];
                    final isCurrent = a.uid == currentUid;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.active
                              ? const Color(0xFF6C63FF)
                              : Colors.grey,
                          child: Text(
                            a.name.isNotEmpty
                                ? a.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          a.name.isNotEmpty ? a.name : a.email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${a.email}\n'
                          '${a.active ? "Active" : "Deactivated"}'
                          '${isCurrent ? " • Current" : ""}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'toggle') await _toggleActive(a);
                            if (v == 'delete') await _delete(a);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(a.active
                                  ? 'Deactivate'
                                  : 'Activate'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete from device'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
