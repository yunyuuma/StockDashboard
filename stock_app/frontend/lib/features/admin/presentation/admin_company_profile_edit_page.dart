import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/admin_company_profile_repository.dart';
import '../domain/company_profile_admin.dart';

class AdminCompanyProfileEditPage extends StatefulWidget {
  const AdminCompanyProfileEditPage({
    super.key,
    required this.stockCode,
  });

  final String stockCode;

  @override
  State<AdminCompanyProfileEditPage> createState() =>
      _AdminCompanyProfileEditPageState();
}

class _AdminCompanyProfileEditPageState
    extends State<AdminCompanyProfileEditPage> {
  final AdminCompanyProfileRepository repository =
      AdminCompanyProfileRepository();

  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mapQueryController = TextEditingController();
  final TextEditingController _trendsKeywordController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _autoFillingStructured = false;
  String? _error;

  CompanyProfileAdmin? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await repository.fetchProfile(widget.stockCode);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _websiteController.text = profile.website;
        _descriptionController.text = profile.description;
        _mapQueryController.text = profile.mapQuery;
        _trendsKeywordController.text = profile.trendsKeyword;
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

  Future<void> _autoFillStructuredData() async {
    if (_autoFillingStructured) return;

    setState(() {
      _autoFillingStructured = true;
    });

    try {
      await repository.autoFillWithStructuredData(widget.stockCode);
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Structured補完を実行しました。'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Structured補完失敗: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _autoFillingStructured = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final profile = _profile;
    if (_saving || profile == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final bool wasRegistered = profile.registered;

      final CompanyProfileAdmin saved = wasRegistered
          ? await repository.updateProfile(
              stockCode: widget.stockCode,
              website: _websiteController.text.trim(),
              description: _descriptionController.text.trim(),
              mapQuery: _mapQueryController.text.trim(),
              trendsKeyword: _trendsKeywordController.text.trim(),
            )
          : await repository.createProfile(
              stockCode: widget.stockCode,
              website: _websiteController.text.trim(),
              description: _descriptionController.text.trim(),
              mapQuery: _mapQueryController.text.trim(),
              trendsKeyword: _trendsKeywordController.text.trim(),
            );

      if (!mounted) return;

      setState(() {
        _profile = saved;
        _websiteController.text = saved.website;
        _descriptionController.text = saved.description;
        _mapQueryController.text = saved.mapQuery;
        _trendsKeywordController.text = saved.trendsKeyword;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasRegistered ? '企業情報を更新しました。' : '企業情報を登録しました。'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失敗: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _descriptionController.dispose();
    _mapQueryController.dispose();
    _trendsKeywordController.dispose();
    repository.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _statusChip(bool registered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: registered ? const Color(0xFFEAFBF1) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        registered ? '登録済み' : '未登録',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: registered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('企業情報編集 ${widget.stockCode}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/admin/company-profiles'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _load,
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

          if (_error != null || profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error ?? 'データ取得に失敗しました',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              profile.stockCode,
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.companyName.isNotEmpty
                                      ? profile.companyName
                                      : profile.stockCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${profile.market} / ${profile.industry}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusChip(profile.registered),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed:
                      _autoFillingStructured ? null : _autoFillStructuredData,
                  icon: _autoFillingStructured
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.language),
                  label: Text(
                    _autoFillingStructured ? '補完中...' : 'Structured補完',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Webサイト'),
              _textField(
                controller: _websiteController,
                hint: '例: https://global.toyota/',
              ),
              const SizedBox(height: 16),
              _fieldLabel('概要'),
              _textField(
                controller: _descriptionController,
                hint: '企業概要を入力',
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Googleマップ検索語'),
              _textField(
                controller: _mapQueryController,
                hint: '例: トヨタ自動車 本社',
              ),
              const SizedBox(height: 16),
              _fieldLabel('Google Trends キーワード'),
              _textField(
                controller: _trendsKeywordController,
                hint: '例: トヨタ自動車',
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving
                        ? '保存中...'
                        : (profile.registered ? '更新' : '新規登録'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}