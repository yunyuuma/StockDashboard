import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/favorite_api_repository.dart';
import '../data/stock_api_repository.dart';
import '../domain/company.dart';
import '../domain/app_session.dart';
import 'components/stock_empty_view.dart';
import 'components/stock_error_view.dart';
import 'components/stock_list_card.dart';
import 'components/stock_loading_view.dart';
import 'components/stock_market_chip_row.dart';
import 'components/stock_search_header.dart';

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final StockApiRepository stockApiRepository = StockApiRepository();
  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int get _userId => AppSession.userId ?? 0;
  final int _pageSize = 30;

  List<Company> _all = [];
  Set<String> _favoriteCodes = {};
  List<String> _markets = [];

  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _updatingFavorite = false;
  bool _hasMore = true;
  String? _error;

  int _page = 0;
  String _query = '';
  String? _marketFilter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitial();

    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _query = _searchController.text.trim();
        });
        _reloadByCondition();
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

  Future<void> _reloadByCondition() async {
    if (!mounted) return;

    setState(() {
      _page = 0;
      _hasMore = true;
      _all = [];
      _error = null;
      _initialLoading = true;
    });

    await _loadNextPage(resetError: false);

    if (mounted) {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage({bool resetError = true}) async {
    if (_pageLoading || !_hasMore) return;

    setState(() {
      _pageLoading = true;
      if (resetError) {
        _error = null;
      }
    });

    try {
      final pageStocks = await stockApiRepository.fetchStocks(
        page: _page,
        size: _pageSize,
        query: _query,
        market: _marketFilter,
      );

      if (pageStocks.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasMore = false;
        });
        return;
      }

      final merged = pageStocks.map((stock) {
        return stock.copyWith(
          favorite: _favoriteCodes.contains(stock.code),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _all.addAll(merged);
        _page++;
        if (merged.length < _pageSize) {
          _hasMore = false;
        }

        final newMarkets = _all
            .map((e) => e.market)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        _markets = newMarkets;
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

  void _setMarketFilter(String? market) {
    setState(() {
      _marketFilter = market;
    });
    _reloadByCondition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    stockApiRepository.dispose();
    favoriteApiRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
              onPressed: () {
                context.go('/mypage');
              },
              icon: const Icon(Icons.person),
              tooltip: 'マイページ',
            ),
          IconButton(
              onPressed: () {
                context.go('/ai-advisor');
              },
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: 'AI相談',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/favorites');
              },
              icon: const Icon(Icons.star, size: 18),
              label: const Text('お気に入り'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
          StockSearchHeader(controller: _searchController),
          StockMarketChipRow(
            markets: _markets,
            selectedMarket: _marketFilter,
            onSelected: _setMarketFilter,
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_initialLoading) {
                  return const StockLoadingView();
                }

                if (_error != null && _all.isEmpty) {
                  return StockErrorView(
                    title: 'データ取得に失敗しました',
                    message: _error!,
                    onRetry: _loadInitial,
                  );
                }

                if (_all.isEmpty) {
                  return const StockEmptyView(
                    message: '該当する銘柄がありません',
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _all.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _all.length) {
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

                    final company = _all[index];
                    return StockListCard(
                      company: company,
                      onTap: () => context.go('/stock/${company.code}'),
                      onFavoriteTap: () => _toggleFavorite(company),
                      favoriteTooltip:
                          company.favorite ? 'お気に入り解除' : 'お気に入り登録',
                          onAiTap: () => context.go('/ai-advisor/stocks/${company.code}'),
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