import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final AuthService _authService = AuthService();
  List<DeviceAccount> _accounts = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _authService.getDeviceAccounts();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    }
  }

  /// Asks for the account's password (Firebase requires this to change or
  /// delete a login), then runs [action]. Returns true on success.
  Future<bool> _withPassword(
    DeviceAccount account,
    String title,
    String confirmLabel,
    Future<void> Function(String password) action,
  ) async {
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account: ${account.email}'),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (ok != true || passCtrl.text.isEmpty) return false;

    setState(() => _busy = true);
    try {
      await action(passCtrl.text);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: wrong password or network error.')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStatus(DeviceAccount account) async {
    final goingInactive = account.status != 'inactive';
    final newStatus = goingInactive ? 'inactive' : 'active';
    final success = await _withPassword(
      account,
      goingInactive ? 'Deactivate Account' : 'Activate Account',
      goingInactive ? 'Deactivate' : 'Activate',
      (password) => _authService.setAccountStatus(
        email: account.email,
        password: password,
        status: newStatus,
      ),
    );
    if (success) {
      await _load();
      _maybeSignOutIfCurrent(account.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              goingInactive ? 'Account deactivated.' : 'Account activated.')),
        );
      }
    }
  }

  Future<void> _deleteAccount(DeviceAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'This permanently deletes "${account.name.isEmpty ? account.email : account.name}" '
          'and all of its data. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _withPassword(
      account,
      'Confirm Deletion',
      'Delete',
      (password) => _authService.deleteAccountByPassword(
        email: account.email,
        password: password,
      ),
    );
    if (success) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted.')),
        );
      }
    }
  }

  void _maybeSignOutIfCurrent(String uid) {
    if (_authService.currentUser?.uid == uid) {
      _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _accounts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No accounts found on this device yet.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final a = _accounts[i];
                          final isCurrent =
                              _authService.currentUser?.uid == a.uid;
                          final isActive = a.status != 'inactive';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF6C63FF)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isActive
                                      ? const Color(0xFF6C63FF)
                                      : Colors.grey,
                                  child: Text(
                                    (a.name.isNotEmpty
                                            ? a.name[0]
                                            : a.email.isNotEmpty
                                                ? a.email[0]
                                                : '?')
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.name.isEmpty ? 'Unnamed' : a.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(a.email,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isActive
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            const Text('(current)',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6C63FF))),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'toggle') _toggleStatus(a);
                                    if (v == 'delete') _deleteAccount(a);
                                    if (v == 'forget') {
                                      _authService
                                          .forgetDeviceAccount(a.uid)
                                          .then((_) => _load());
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                          isActive ? 'Deactivate' : 'Activate'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'forget',
                                      child: Text('Remove from this list'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                if (_busy)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
