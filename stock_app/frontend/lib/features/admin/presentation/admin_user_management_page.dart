import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/admin_user_repository.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final AdminUserRepository _repository = AdminUserRepository();

  bool _loading = true;
  String? _error;
  List<AdminUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _repository.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeRole(AdminUser user, String role) async {
    try {
      final updated = await _repository.updateRole(
        userId: user.userId,
        role: role,
      );

      if (!mounted) return;

      setState(() {
        _users = _users.map((e) {
          if (e.userId == updated.userId) return updated;
          return e;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('権限を更新しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('権限更新に失敗しました: $e')),
      );
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ユーザ削除'),
        content: Text('${user.userName} を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repository.deleteUser(user.userId);

      if (!mounted) return;

      setState(() {
        _users.removeWhere((e) => e.userId == user.userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザを削除しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  String _roleLabel(String role) {
    return role == 'ADMIN' ? '管理者' : '一般ユーザ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ユーザ管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: '再読込',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (_users.isEmpty) {
            return const Center(child: Text('ユーザがありません。'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = _users[index];
              final isAdmin = user.role == 'ADMIN';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          user.userName.isNotEmpty
                              ? user.userName.characters.first
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '2段階認証: ${user.twoFactorEnabled ? 'ON' : 'OFF'}',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: isAdmin ? 'ADMIN' : 'USER',
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'USER',
                            child: Text('一般ユーザ'),
                          ),
                          DropdownMenuItem(
                            value: 'ADMIN',
                            child: Text('管理者'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _changeRole(user, value);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: isAdmin ? '管理者は削除できません' : '削除',
                        onPressed: isAdmin ? null : () => _deleteUser(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}