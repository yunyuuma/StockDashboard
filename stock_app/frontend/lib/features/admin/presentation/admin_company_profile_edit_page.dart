import 'package:flutter/material.dart';

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
  final TextEditingController _descriptionController =
      TextEditingController();
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
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await repository.fetchProfile(widget.stockCode);

      _profile = profile;
      _websiteController.text = profile.website;
      _descriptionController.text = profile.description;
      _mapQueryController.text = profile.mapQuery;
      _trendsKeywordController.text = profile.trendsKeyword;
    } catch (e) {
      _error = e.toString();
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
        const SnackBar(content: Text('structured data 自動補完を実行しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('structured data補完失敗: $e')),
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
    if (_saving || _profile == null) return;

    setState(() {
      _saving = true;
    });

    try {
      late final CompanyProfileAdmin saved;

      if (_profile!.registered) {
        saved = await repository.updateProfile(
          stockCode: widget.stockCode,
          website: _websiteController.text.trim(),
          description: _descriptionController.text.trim(),
          mapQuery: _mapQueryController.text.trim(),
          trendsKeyword: _trendsKeywordController.text.trim(),
        );
      } else {
        saved = await repository.createProfile(
          stockCode: widget.stockCode,
          website: _websiteController.text.trim(),
          description: _descriptionController.text.trim(),
          mapQuery: _mapQueryController.text.trim(),
          trendsKeyword: _trendsKeywordController.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() {
        _profile = saved;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved.registered ? '企業情報を保存しました' : '企業情報を登録しました'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失敗: $e')),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.companyName.isNotEmpty
                                  ? profile.companyName
                                  : widget.stockCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          _statusChip(profile.registered),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${profile.market} / ${profile.industry}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _autoFillingStructured
                          ? null
                          : _autoFillStructuredData,
                      icon: _autoFillingStructured
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.language),
                      label: Text(
                        _autoFillingStructured ? '補完中...' : 'structured補完',
                      ),
                    ),
                  ),
                ],
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
                height: 48,
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