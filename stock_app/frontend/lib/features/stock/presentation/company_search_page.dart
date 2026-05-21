import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/favorite_api_repository.dart';
import '../data/price_repository.dart';
import '../domain/app_session.dart';
import '../domain/company.dart';
import 'components/stock_empty_view.dart';
import 'components/stock_error_view.dart';
import 'components/stock_list_card.dart';
import 'components/stock_loading_view.dart';
import 'components/stock_market_chip_row.dart';
import 'components/stock_search_header.dart';

class CompanySearchPage extends StatefulWidget {
  const CompanySearchPage({super.key});

  @override
  State<CompanySearchPage> createState() => _CompanySearchPageState();
}

class _CompanySearchPageState extends State<CompanySearchPage> {
  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();

  static const String workerBaseUrl = 'https://workers.gikiin67.workers.dev';
  final PriceRepository priceRepository =
      PriceRepository(proxyBaseUrl: workerBaseUrl);

  final TextEditingController _searchController = TextEditingController();

  List<Company> _all = [];
  List<Company> _filtered = [];

  bool _loading = true;
  bool _updatingFavorite = false;
  String? _error;

  String _query = '';
  String? _marketFilter;

  @override
  void initState() {
    super.initState();
    _load();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
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
      final favorites = await favoriteApiRepository.fetchFavorites(
        userId: AppSession.userId!,
      );

      final codes = favorites.map((e) => e.code).toList();

      final quotes = codes.isEmpty
          ? <String, dynamic>{}
          : await priceRepository.refreshQuotes(
              codes,
              batchSize: 10,
              delayBetweenBatches: const Duration(milliseconds: 200),
            );

      final merged = favorites.map((company) {
        final quote = quotes[company.code];
        return company.copyWith(
          favorite: true,
          price: quote?.price ?? 0,
          changePct: quote?.changePct ?? 0,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _all = merged;
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

  void _applyFilter() {
    final q = _query.toLowerCase();

    _filtered = _all.where((c) {
      final hit = q.isEmpty ||
          c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.industry.toLowerCase().contains(q) ||
          c.market.toLowerCase().contains(q);

      final marketOk = _marketFilter == null || c.market == _marketFilter;
      return hit && marketOk;
    }).toList();
  }

  void _setMarketFilter(String? market) {
    setState(() {
      _marketFilter = market;
      _applyFilter();
    });
  }

  Future<void> _toggleFavorite(Company company) async {
    if (_updatingFavorite) return;

    setState(() {
      _updatingFavorite = true;
    });

    try {
      await favoriteApiRepository.deleteFavorite(
        userId: AppSession.userId!,
        stockCode: company.code,
      );

      if (!mounted) return;

      setState(() {
        _all = _all.where((e) => e.code != company.code).toList();
        _applyFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${company.name} をお気に入りから削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingFavorite = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    favoriteApiRepository.dispose();
    priceRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markets = _all
        .map((e) => e.market)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/companies'),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'お気に入り一覧',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
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
          StockSearchHeader(controller: _searchController),
          StockMarketChipRow(
            markets: markets,
            selectedMarket: _marketFilter,
            onSelected: _setMarketFilter,
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const StockLoadingView();
                }

                if (_error != null) {
                  return StockErrorView(
                    title: 'お気に入りデータの取得に失敗しました',
                    message: _error!,
                    onRetry: _load,
                  );
                }

                if (_filtered.isEmpty) {
                  return const StockEmptyView(
                    message: 'お気に入り銘柄がありません',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final company = _filtered[index];
                    return StockListCard(
                      company: company,
                      showPriceInfo: true,
                      onTap: () => context.go('/stock/${company.code}'),
                      onFavoriteTap: () => _toggleFavorite(company),
                      favoriteTooltip: 'お気に入り解除',
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