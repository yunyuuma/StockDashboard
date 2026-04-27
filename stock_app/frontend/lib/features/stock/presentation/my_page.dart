import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_api_repository.dart';
import '../data/user_api_repository.dart';
import '../domain/app_session.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final UserApiRepository _userRepository = UserApiRepository();
  final AuthApiRepository _authRepository = AuthApiRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _userRepository.dispose();
    _authRepository.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = AppSession.userId;

    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'ログイン情報がありません。';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _userRepository.fetchUser(userId: userId);

      _nameController.text = profile.name;
      _emailController.text = profile.email;

      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _saveUser() async {
    final userId = AppSession.userId;

    if (userId == null) {
      setState(() {
        _error = 'ログイン情報がありません。';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await _userRepository.updateUser(
        userId: userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      await AppSession.save(
        token: AppSession.token ?? '',
        userId: updated.id,
        name: updated.name,
        email: updated.email,
        role: updated.role,
      );

      if (!mounted) return;

      setState(() {
        _profile = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザ情報を更新しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authRepository.logout(AppSession.token);
    } catch (_) {
      // サーバ側ログアウト失敗でもローカルは消す
    }

    await AppSession.clear();

    if (!mounted) return;
    context.go('/login');
  }

  String _roleLabel(int role) {
    if (role == 2) return '管理者';
    return '一般ユーザ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUser,
            icon: const Icon(Icons.refresh),
            tooltip: '再読込',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUser,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeaderCard(profile),
        const SizedBox(height: 16),
        _buildEditCard(profile),
        const SizedBox(height: 16),
        _buildSettingCard(profile),
        const SizedBox(height: 16),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildHeaderCard(UserProfile? profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
              child: const Icon(
                Icons.person,
                size: 34,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name.isNotEmpty == true
                        ? profile!.name
                        : AppSession.name ?? '-',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.email.isNotEmpty == true
                        ? profile!.email
                        : AppSession.email ?? '-',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _roleLabel(profile?.role ?? AppSession.role ?? 1),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(UserProfile? profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザ名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveUser,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? '保存中...' : '保存する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(UserProfile? profile) {
    final twoFactor = profile?.twoFactorEnabled ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.badge_outlined,
              title: 'ユーザID',
              value: '${profile?.id ?? AppSession.userId ?? '-'}',
            ),
            const Divider(height: 28),
            _InfoRow(
              icon: Icons.security,
              title: '2段階認証',
              value: twoFactor ? 'ON' : 'OFF',
            ),
            const Divider(height: 28),
            _InfoRow(
              icon: Icons.admin_panel_settings_outlined,
              title: '権限',
              value: _roleLabel(profile?.role ?? AppSession.role ?? 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('ログアウト'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}