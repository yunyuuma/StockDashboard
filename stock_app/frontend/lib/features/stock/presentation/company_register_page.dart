import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/favorite_api_repository.dart';
import '../data/price_repository.dart';
import '../data/stock_api_repository.dart';
import '../domain/company.dart';

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final StockApiRepository stockApiRepository = StockApiRepository();
  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();

  static const String workerBaseUrl = 'https://workers.gikiin67.workers.dev';

  final PriceRepository priceRepository =
      PriceRepository(proxyBaseUrl: workerBaseUrl);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final int _userId = 1;
  final int _pageSize = 100;

  List<Company> _all = [];
  List<Company> _filtered = [];
  Set<String> _favoriteCodes = {};

  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _updatingFavorite = false;
  bool _hasMore = true;
  String? _error;

  int _page = 0;
  String _query = '';
  String? _marketFilter;

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
        _applyFilter();
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        _loadNextPage();
      }
    });
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;

    setState(() {
      _initialLoading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
      _all = [];
      _filtered = [];
    });

    try {
      final favorites =
          await favoriteApiRepository.fetchFavorites(userId: _userId);

      _favoriteCodes = favorites.map((e) => e.code).toSet();

      await _loadNextPage(resetError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _loadNextPage({bool resetError = true}) async {
    if (_pageLoading || !_hasMore) return;

    if (mounted) {
      setState(() {
        _pageLoading = true;
        if (resetError) {
          _error = null;
        }
      });
    }

    try {
      final pageStocks = await stockApiRepository.fetchStocks(
        page: _page,
        size: _pageSize,
      );

      if (pageStocks.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasMore = false;
        });
        return;
      }

      final codes = pageStocks.map((e) => e.code).toList();

      final quotes = await priceRepository.refreshQuotes(
        codes,
        batchSize: 15,
        delayBetweenBatches: const Duration(milliseconds: 200),
      );

      final merged = pageStocks.map((stock) {
        final quote = quotes[stock.code];
        return stock.copyWith(
          favorite: _favoriteCodes.contains(stock.code),
          price: quote?.price ?? 0,
          changePct: quote?.changePct ?? 0,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _all.addAll(merged);
        _page++;
        if (merged.length < _pageSize) {
          _hasMore = false;
        }
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
          _pageLoading = false;
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
      if (company.favorite) {
        await favoriteApiRepository.deleteFavorite(
          userId: _userId,
          stockCode: company.code,
        );
        _favoriteCodes.remove(company.code);
      } else {
        await favoriteApiRepository.addFavorite(
          userId: _userId,
          stockCode: company.code,
        );
        _favoriteCodes.add(company.code);
      }

      if (!mounted) return;

      setState(() {
        _all = _all.map((e) {
          if (e.code == company.code) {
            return e.copyWith(favorite: !e.favorite);
          }
          return e;
        }).toList();
        _applyFilter();
      });
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

  Color _marketChipColor(String market) {
    switch (market) {
      case 'プライム':
        return const Color(0xFFE8F1FF);
      case 'スタンダード':
        return const Color(0xFFF3F4F6);
      case 'グロース':
        return const Color(0xFFEAFBF1);
      default:
        return const Color(0xFFF4F4F5);
    }
  }

  Color _marketTextColor(String market) {
    switch (market) {
      case 'プライム':
        return const Color(0xFF2563EB);
      case 'スタンダード':
        return const Color(0xFF4B5563);
      case 'グロース':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF52525B);
    }
  }

  Widget _buildCard(Company company) {
    final isPlus = company.changePct >= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.go('/stock/${company.code}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    company.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _toggleFavorite(company),
                          icon: Icon(
                            company.favorite
                                ? Icons.star
                                : Icons.star_border,
                            color: company.favorite ? Colors.amber : Colors.grey,
                          ),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _marketChipColor(company.market),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            company.market,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _marketTextColor(company.market),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            company.industry,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '現在価格',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                company.price > 0
                                    ? '¥${company.price.toStringAsFixed(0)}'
                                    : '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '前日比',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              company.price > 0
                                  ? '${isPlus ? '+' : ''}${company.changePct.toStringAsFixed(2)}%'
                                  : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isPlus
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    stockApiRepository.dispose();
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
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          '銘柄一覧',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('再読込'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'コード・企業名・業種・市場で検索',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (markets.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('すべて'),
                              selected: _marketFilter == null,
                              onSelected: (_) => _setMarketFilter(null),
                            ),
                          ),
                          ...markets.map(
                            (market) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(market),
                                selected: _marketFilter == market,
                                onSelected: (_) => _setMarketFilter(market),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_initialLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_error != null && _all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 56,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'データ取得に失敗しました',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadInitial,
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      '該当する銘柄がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _filtered.length) {
                      if (_pageLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!_hasMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'これ以上データはありません',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final company = _filtered[index];
                    return _buildCard(company);
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