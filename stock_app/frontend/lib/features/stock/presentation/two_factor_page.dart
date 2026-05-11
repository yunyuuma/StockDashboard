import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_api_repository.dart';
import '../domain/app_session.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({
    super.key,
    required this.challengeId,
  });

  final String challengeId;

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final _codeController = TextEditingController();
  final _repository = AuthApiRepository();

  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _repository.verifyTwoFactor(
        challengeId: widget.challengeId,
        code: _codeController.text.trim(),
      );

      await AppSession.save(
        token: res.token,
        userId: res.userId,
        name: res.name,
        email: res.email,
        role: res.role,
      );

      if (!mounted) return;

      if (res.role == 2) {
        context.go('/admin');
      } else {
        context.go('/companies');
      }
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

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      await _repository.resendTwoFactor(
        challengeId: widget.challengeId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('認証コードを再送しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('2段階認証'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Icon(
            Icons.verified_user,
            size: 64,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(height: 20),
          const Text(
            '認証コードを入力してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '認証コード',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('認証する'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resending ? null : _resend,
            child: Text(_resending ? '再送中...' : '認証コードを再送'),
          ),
        ],
      ),
    );
  }
}