import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/favorite_api_repository.dart';
import '../data/price_repository.dart';
import '../domain/company.dart';

class CompanySearchPage extends StatefulWidget {
  const CompanySearchPage({super.key});

  @override
  State<CompanySearchPage> createState() => _CompanySearchPageState();
}

class _CompanySearchPageState extends State<CompanySearchPage> {
  static const String workerBaseUrl = 'https://workers.gikiin67.workers.dev';

  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();

  final PriceRepository priceRepository =
      PriceRepository(proxyBaseUrl: workerBaseUrl);

  final TextEditingController _searchController = TextEditingController();

  List<Company> _all = [];
  List<Company> _filtered = [];

  bool _loading = true;
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
      final favorites = await favoriteApiRepository.fetchFavorites(userId: 1);
      final codes = favorites.map((e) => e.code).toList();

      final quotes = await priceRepository.refreshQuotes(
        codes,
        batchSize: 15,
        delayBetweenBatches: const Duration(milliseconds: 200),
      );

      final merged = favorites.map((company) {
        final quote = quotes[company.code];
        if (quote == null) return company;

        return company.copyWith(
          price: quote.price,
          changePct: quote.changePct,
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
      appBar: AppBar(
        title: const Text('お気に入り株価一覧'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('再読込'),
              onPressed: _load,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'コード・企業名・業種・市場で検索',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          if (markets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('すべて'),
                    selected: _marketFilter == null,
                    onSelected: (_) => _setMarketFilter(null),
                  ),
                  ...markets.map(
                    (market) => ChoiceChip(
                      label: Text(market),
                      selected: _marketFilter == market,
                      onSelected: (_) => _setMarketFilter(market),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('お気に入り銘柄がありません'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final company = _filtered[index];
                  final isPlus = company.changePct >= 0;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.go('/stock/${company.code}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(
                                company.code,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${company.market} / ${company.industry}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '¥${company.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${isPlus ? '+' : ''}${company.changePct.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPlus ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}