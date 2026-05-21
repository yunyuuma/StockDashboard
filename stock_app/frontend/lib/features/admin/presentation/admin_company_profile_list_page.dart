import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/admin_company_profile_repository.dart';
import '../domain/company_profile_admin.dart';

class AdminCompanyProfileListPage extends StatefulWidget {
  const AdminCompanyProfileListPage({super.key});

  @override
  State<AdminCompanyProfileListPage> createState() =>
      _AdminCompanyProfileListPageState();
}

class _AdminCompanyProfileListPageState
    extends State<AdminCompanyProfileListPage> {
  final AdminCompanyProfileRepository repository =
      AdminCompanyProfileRepository();

  final TextEditingController _searchController = TextEditingController();

  List<CompanyProfileAdmin> _all = [];
  List<CompanyProfileAdmin> _filtered = [];

  bool _loading = true;
  bool _autoFillingStructured = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _applyFilter();
      });
    });
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await repository.fetchProfiles();

      if (!mounted) return;

      setState(() {
        _all = list;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _autoFillStructuredData(String stockCode) async {
    if (_autoFillingStructured) return;

    setState(() {
      _autoFillingStructured = true;
    });

    try {
      await repository.autoFillWithStructuredData(stockCode);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$stockCode をstructured dataで補完しました')),
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

  void _applyFilter() {
    _filtered = _all.where((e) {
      if (_query.isEmpty) return true;

      return e.stockCode.toLowerCase().contains(_query) ||
          e.companyName.toLowerCase().contains(_query) ||
          e.market.toLowerCase().contains(_query) ||
          e.industry.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    repository.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('企業情報管理'),
        actions: [
          IconButton(
            onPressed: () {
              context.go('/mypage');
            },
            icon: const Icon(Icons.person),
            tooltip: 'マイページ',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('再読込'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '銘柄コード・企業名・市場・業種で検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (_filtered.isEmpty) {
                  return const Center(
                    child: Text('対象の銘柄がありません'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                context.go('/admin/company-profiles/${item.stockCode}');
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.stockCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.companyName.isNotEmpty
                                                    ? item.companyName
                                                    : item.stockCode,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            _statusChip(item.registered),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.market} / ${item.industry}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.website.isNotEmpty
                                              ? item.website
                                              : 'クリックして企業情報を登録',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: item.registered
                                                ? Colors.grey[600]
                                                : const Color(0xFFD97706),
                                            fontSize: 13,
                                            fontWeight: item.registered
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _autoFillingStructured
                                        ? null
                                        : () => _autoFillStructuredData(item.stockCode),
                                    icon: const Icon(Icons.language),
                                    label: const Text('structured補完'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}