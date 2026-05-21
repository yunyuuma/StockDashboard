import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../data/favorite_api_repository.dart';
import '../data/stock_detail_api_repository.dart';
import '../data/stock_news_api_repository.dart';
import '../data/stock_news.dart';
import '../domain/app_session.dart';
import '../domain/stock_detail_models.dart';
import 'components/stock_error_view.dart';
import 'components/stock_loading_view.dart';
import 'components/stock_section_card.dart';
import '../../trading/data/trading_repository.dart';
import '../../trading/domain/trading_models.dart';
import '../../trading/presentation/order_dialog.dart';

class StockDetailPage extends StatefulWidget {
  const StockDetailPage({super.key, required this.code});

  final String code;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StockDetailPageState extends State<StockDetailPage>
    with SingleTickerProviderStateMixin {
  int? _touchedPriceIndex;
  int? _touchedMaIndex;
  int? _touchedRsiIndex;

  final StockDetailApiRepository repository = StockDetailApiRepository();
  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();
  final StockNewsApiRepository newsRepo = StockNewsApiRepository();
  final TradingRepository tradingRepository = TradingRepository();

  OrderBook? _orderBook;
  bool _orderBookLoading = false;
  List<TradingOrder> _openOrders = [];
  bool _openOrdersLoading = false;

  late final TabController _tabController;
  final ScrollController _newsScrollController = ScrollController();

  bool _loading = true;
  bool _favoriteLoading = false;
  bool _isFavorite = false;
  bool _newsLoading = true;
  String? _error;

  StockDetailSummary? _summary;
  List<StockChartPoint> _chart = [];
  List<StockNews> _allNews = [];
  List<StockNews> _visibleNews = [];
  Set<String> _readNewsKeys = {};
  StockMetrics? _metrics;
  StockCompanyInfo? _company;

  String _selectedRange = '6M';
  String _chartType = 'candle';
  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _buildGoogleMapsUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.google.com/maps/search/?api=1&query=$encoded';
  }

  String _buildGoogleTrendsUrl(String keyword) {
    final encoded = Uri.encodeComponent(keyword);
    return 'https://trends.google.com/trends/explore?q=$encoded&geo=JP';
  }

  static const int _olderBatchSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _newsScrollController.addListener(_onNewsScroll);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _newsLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        repository.fetchSummary(widget.code),
        repository.fetchChart(widget.code),
        repository.fetchMetrics(widget.code),
        repository.fetchCompany(widget.code),
        favoriteApiRepository.fetchFavorites(userId: AppSession.userId!),
        newsRepo.fetchNews(widget.code),
        _loadReadNewsKeys(),
      ]);

      final summary = results[0] as StockDetailSummary;
      final chart = results[1] as List<StockChartPoint>;
      final metrics = results[2] as StockMetrics;
      final company = results[3] as StockCompanyInfo;
      final favorites = results[4] as List<dynamic>;
      final news = results[5] as List<StockNews>;
      final readKeys = results[6] as Set<String>;

      final favoriteCodes = favorites.map((e) => e.code as String).toSet();

      if (!mounted) return;

      final sortedNews = [...news]
        ..sort((a, b) {
          final ad = _parseNewsDate(a.publishedAt);
          final bd = _parseNewsDate(b.publishedAt);
          return bd.compareTo(ad);
        });

      setState(() {
        _summary = summary;
        _loadOrderBook(summary);
        _loadOpenOrders();
        _chart = chart;
        _metrics = metrics;
        _company = company;
        _allNews = sortedNews;
        _readNewsKeys = readKeys;
        _isFavorite = favoriteCodes.contains(widget.code);
        _setupInitialVisibleNews();
        _newsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _newsLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _bottomTitleStep(int length) {
    if (length <= 12) return 1;
    if (length <= 24) return 2;
    if (length <= 48) return 4;
    if (length <= 90) return 8;
    if (length <= 140) return 12;
    return 16;
  }

  String _safeDateLabel(String raw) {
    if (raw.length >= 10) {
      return raw.substring(0, 10).replaceAll('-', '/');
    }
    return raw;
  }

  String _formatCompactVolumeLabel(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}億';
    }
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(0)}万';
    }
    return value.toStringAsFixed(0);
  }

  String _documentTypeJa(String value) {
    switch (value.trim()) {
      case 'FYFinancialStatements_Consolidated_JP':
        return '決算短信（連結・日本基準）';
      case 'FYFinancialStatements_Consolidated_US':
        return '決算短信（連結・米国基準）';
      case 'FYFinancialStatements_NonConsolidated_JP':
        return '決算短信（非連結・日本基準）';

      case '1QFinancialStatements_Consolidated_JP':
        return '第1四半期決算短信（連結・日本基準）';
      case '1QFinancialStatements_Consolidated_US':
        return '第1四半期決算短信（連結・米国基準）';
      case '1QFinancialStatements_NonConsolidated_JP':
        return '第1四半期決算短信（非連結・日本基準）';

      case '2QFinancialStatements_Consolidated_JP':
        return '第2四半期決算短信（連結・日本基準）';
      case '2QFinancialStatements_Consolidated_US':
        return '第2四半期決算短信（連結・米国基準）';
      case '2QFinancialStatements_NonConsolidated_JP':
        return '第2四半期決算短信（非連結・日本基準）';

      case '3QFinancialStatements_Consolidated_JP':
        return '第3四半期決算短信（連結・日本基準）';
      case '3QFinancialStatements_Consolidated_US':
        return '第3四半期決算短信（連結・米国基準）';
      case '3QFinancialStatements_NonConsolidated_JP':
        return '第3四半期決算短信（非連結・日本基準）';

      case 'OtherPeriodFinancialStatements_Consolidated_JP':
        return 'その他四半期決算短信（連結・日本基準）';
      case 'OtherPeriodFinancialStatements_Consolidated_US':
        return 'その他四半期決算短信（連結・米国基準）';
      case 'OtherPeriodFinancialStatements_NonConsolidated_JP':
        return 'その他四半期決算短信（非連結・日本基準）';

      case 'FYFinancialStatements_Consolidated_JMIS':
        return '決算短信（連結・JMIS）';
      case '1QFinancialStatements_Consolidated_JMIS':
        return '第1四半期決算短信（連結・JMIS）';
      case '2QFinancialStatements_Consolidated_JMIS':
        return '第2四半期決算短信（連結・JMIS）';
      case '3QFinancialStatements_Consolidated_JMIS':
        return '第3四半期決算短信（連結・JMIS）';
      case 'OtherPeriodFinancialStatements_Consolidated_JMIS':
        return 'その他四半期決算短信（連結・JMIS）';

      case 'FYFinancialStatements_NonConsolidated_IFRS':
        return '決算短信（非連結・IFRS）';
      case '1QFinancialStatements_NonConsolidated_IFRS':
        return '第1四半期決算短信（非連結・IFRS）';
      case '2QFinancialStatements_NonConsolidated_IFRS':
        return '第2四半期決算短信（非連結・IFRS）';
      case '3QFinancialStatements_NonConsolidated_IFRS':
        return '第3四半期決算短信（非連結・IFRS）';
      case 'OtherPeriodFinancialStatements_NonConsolidated_IFRS':
        return 'その他四半期決算短信（非連結・IFRS）';

      case 'FYFinancialStatements_Consolidated_IFRS':
        return '決算短信（連結・IFRS）';
      case '1QFinancialStatements_Consolidated_IFRS':
        return '第1四半期決算短信（連結・IFRS）';
      case '2QFinancialStatements_Consolidated_IFRS':
        return '第2四半期決算短信（連結・IFRS）';
      case '3QFinancialStatements_Consolidated_IFRS':
        return '第3四半期決算短信（連結・IFRS）';
      case 'OtherPeriodFinancialStatements_Consolidated_IFRS':
        return 'その他四半期決算短信（連結・IFRS）';

      case 'FYFinancialStatements_NonConsolidated_Foreign':
        return '決算短信（非連結・外国株）';
      case '1QFinancialStatements_NonConsolidated_Foreign':
        return '第1四半期決算短信（非連結・外国株）';
      case '2QFinancialStatements_NonConsolidated_Foreign':
        return '第2四半期決算短信（非連結・外国株）';
      case '3QFinancialStatements_NonConsolidated_Foreign':
        return '第3四半期決算短信（非連結・外国株）';
      case 'OtherPeriodFinancialStatements_NonConsolidated_Foreign':
        return 'その他四半期決算短信（非連結・外国株）';

      case 'FYFinancialStatements_Consolidated_Foreign':
        return '決算短信（連結・外国株）';
      case '1QFinancialStatements_Consolidated_Foreign':
        return '第1四半期決算短信（連結・外国株）';
      case '2QFinancialStatements_Consolidated_Foreign':
        return '第2四半期決算短信（連結・外国株）';
      case '3QFinancialStatements_Consolidated_Foreign':
        return '第3四半期決算短信（連結・外国株）';
      case 'OtherPeriodFinancialStatements_Consolidated_Foreign':
        return 'その他四半期決算短信（連結・外国株）';

      case 'FYFinancialStatements_Consolidated_REIT':
        return '決算短信（REIT）';

      case 'DividendForecastRevision':
        return '配当予想の修正';
      case 'EarnForecastRevision':
        return '業績予想の修正';
      case 'REITDividendForecastRevision':
        return '分配予想の修正';
      case 'REITEarnForecastRevision':
        return '利益予想の修正';

      default:
        if (value.trim().isEmpty) return '-';
        return value;
    }
  }

  Future<Set<String>> _loadReadNewsKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_newsReadPrefsKey())?.toSet() ?? {};
  }

  Future<void> _markNewsAsRead(StockNews news) async {
    final key = news.readKey;
    if (_readNewsKeys.contains(key)) return;

    final updated = {..._readNewsKeys, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_newsReadPrefsKey(), updated.toList());

    if (!mounted) return;
    setState(() {
      _readNewsKeys = updated;
    });
  }

  String _newsReadPrefsKey() => 'read_news_${widget.code}';

  void _setupInitialVisibleNews() {
    if (_allNews.isEmpty) {
      _visibleNews = [];
      return;
    }

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 2));

    final recent = _allNews.where((news) {
      final dt = _parseNewsDate(news.publishedAt);
      return dt.isAfter(cutoff) || dt.isAtSameMomentAs(cutoff);
    }).toList();

    if (recent.isNotEmpty) {
      _visibleNews = recent;
    } else {
      _visibleNews = _allNews.take(_olderBatchSize).toList();
    }
  }

  bool get _hasMoreOlderNews => _visibleNews.length < _allNews.length;

  void _appendOlderNews() {
    if (!_hasMoreOlderNews) return;

    final currentCount = _visibleNews.length;
    final nextCount = math.min(currentCount + _olderBatchSize, _allNews.length);

    if (nextCount <= currentCount) return;

    setState(() {
      _visibleNews = _allNews.take(nextCount).toList();
    });
  }

  void _onNewsScroll() {
    if (!_newsScrollController.hasClients) return;

    final position = _newsScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _appendOlderNews();
    }
  }

  DateTime _parseNewsDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    try {
      final normalized = raw.replaceFirst(' ', 'T');
      return DateTime.parse(normalized);
    } catch (_) {}

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    setState(() {
      _favoriteLoading = true;
    });

    try {
      if (_isFavorite) {
        await favoriteApiRepository.deleteFavorite(
          userId: AppSession.userId!,
          stockCode: widget.code,
        );
      } else {
        await favoriteApiRepository.addFavorite(
          userId: AppSession.userId!,
          stockCode: widget.code,
        );
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('お気に入り更新に失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _favoriteLoading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
    }
  }

  Future<void> _loadOrderBook(StockDetailSummary summary) async {
    if (summary.price <= 0) return;

    setState(() {
      _orderBookLoading = true;
    });

    try {
      final board = await tradingRepository.fetchOrderBook(
        stockCode: summary.code,
        currentPrice: summary.price,
      );

      if (!mounted) return;

      setState(() {
        _orderBook = board;
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _orderBookLoading = false;
        });
      }
    }
  }

Future<void> _loadOpenOrders() async {
  if (!mounted) return;

  setState(() {
    _openOrdersLoading = true;
  });

  try {
    final orders = await tradingRepository.fetchOpenOrders();

    if (!mounted) return;

    setState(() {
      _openOrders = orders;
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _openOrders = [];
    });
  } finally {
    if (mounted) {
      setState(() {
        _openOrdersLoading = false;
      });
    }
  }
}

  Future<void> _openOrderFromBoard(double boardPrice) async {
    final s = _summary;
    if (s == null || s.price <= 0) return;

    final result = await showOrderDialog(
      context: context,
      stockCode: s.code,
      stockName: s.name,
      currentPrice: s.price,
      initialSide: boardPrice >= s.price ? 'SELL' : 'BUY',
      initialOrderType: 'LIMIT',
      initialLimitPrice: boardPrice,
    );

    if (!mounted || result == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));

    await _loadOpenOrders();
  }

  Future<void> _reloadAll() async {
    try {
      final summary = await repository.fetchSummary(widget.code);
      final chart = await repository.fetchChart(widget.code);
      final news = await newsRepo.fetchNews(widget.code);
      final metrics = await repository.fetchMetrics(widget.code);
      final company = await repository.fetchCompany(widget.code);

      if (!mounted) return;

      final sortedNews = [...news]
        ..sort((a, b) {
          final ad = _parseNewsDate(a.publishedAt);
          final bd = _parseNewsDate(b.publishedAt);
          return bd.compareTo(ad);
        });

      setState(() {
        _summary = summary;
        _chart = chart;
        _allNews = sortedNews;
        _metrics = metrics;
        _company = company;

        _setupInitialVisibleNews();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('再読み込みに失敗しました: $e')));
    }
  }

  List<StockChartPoint> _filteredChart() {
    if (_chart.isEmpty) return [];
    final total = _chart.length;

    switch (_selectedRange) {
      case '1M':
        return _chart.skip(math.max(0, total - 22)).toList();
      case '3M':
        return _chart.skip(math.max(0, total - 66)).toList();
      case '1Y':
        return _chart.skip(math.max(0, total - 240)).toList();
      case 'ALL':
        return _chart;
      case '6M':
      default:
        return _chart.skip(math.max(0, total - 120)).toList();
    }
  }

  List<double?> _movingAverage(List<StockChartPoint> points, int window) {
    final result = <double?>[];
    for (int i = 0; i < points.length; i++) {
      if (i + 1 < window) {
        result.add(null);
        continue;
      }
      double sum = 0;
      for (int j = i - window + 1; j <= i; j++) {
        sum += points[j].close;
      }
      result.add(sum / window);
    }
    return result;
  }

  List<double?> _rsi14(List<StockChartPoint> points) {
    if (points.length < 15) {
      return List<double?>.filled(points.length, null);
    }

    final result = List<double?>.filled(points.length, null);

    for (int i = 14; i < points.length; i++) {
      double gain = 0;
      double loss = 0;

      for (int j = i - 13; j <= i; j++) {
        final diff = points[j].close - points[j - 1].close;
        if (diff > 0) {
          gain += diff;
        } else {
          loss += diff.abs();
        }
      }

      final avgGain = gain / 14;
      final avgLoss = loss / 14;

      if (avgLoss == 0) {
        result[i] = 100;
      } else {
        final rs = avgGain / avgLoss;
        result[i] = 100 - (100 / (1 + rs));
      }
    }

    return result;
  }

  String _dashIfZero(num? value) {
    if (value == null || value == 0) return '-';
    return value.toString();
  }

  String _formatJapaneseMoney(num? value) {
    if (value == null || value == 0) return '-';

    final v = value.toDouble().abs();
    final sign = value < 0 ? '-' : '';

    if (v >= 1000000000000) {
      final t = v / 1000000000000;
      return '$sign${_trimTrailingZero(t)}兆円';
    }

    if (v >= 100000000) {
      final oku = v / 100000000;
      return '$sign${_trimTrailingZero(oku)}億円';
    }

    if (v >= 10000) {
      final man = v / 10000;
      return '$sign${_trimTrailingZero(man)}万円';
    }

    return '$sign${_trimTrailingZero(v)}円';
  }

  String _formatJapaneseShares(num? value) {
    if (value == null || value == 0) return '-';

    final v = value.toDouble().abs();
    final sign = value < 0 ? '-' : '';

    if (v >= 100000000) {
      final oku = v / 100000000;
      return '$sign${_trimTrailingZero(oku)}億株';
    }

    if (v >= 10000) {
      final man = v / 10000;
      return '$sign${_trimTrailingZero(man)}万株';
    }

    return '$sign${_trimTrailingZero(v)}株';
  }

  String _formatYen(num? value) {
    if (value == null || value == 0) return '-';
    return '${_trimTrailingZero(value.toDouble())}円';
  }

  String _formatPercent(num? value) {
    if (value == null || value == 0) return '-';
    return '${_trimTrailingZero(value.toDouble())}%';
  }

  String _trimTrailingZero(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    if (value >= 100) {
      return value.toStringAsFixed(1);
    }
    if (value >= 10) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(2);
  }

  String _shortDateLabel(String raw) {
    if (raw.length >= 10) {
      return raw.substring(5, 10);
    }
    return raw;
  }

  String _priceAxisLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildHeader() {
    final s = _summary!;
    final isPlus = s.changePct >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    s.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.market} / ${s.industry}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _metricHeaderBox(
                  '現在価格',
                  s.price > 0 ? '¥${s.price.toStringAsFixed(0)}' : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricHeaderBox(
                  '前日比',
                  s.price > 0
                      ? '${isPlus ? '+' : ''}${s.changePct.toStringAsFixed(2)}%'
                      : '-',
                  valueColor: isPlus
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricHeaderBox(String title, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final s = _summary;
    final m = _metrics;

    if (s == null || m == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          // 現在値カード
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(child: _miniMetric('高値', _formatPrice(s.high))),
                      Expanded(child: _miniMetric('安値', _formatPrice(s.low))),
                      Expanded(child: _miniMetric('始値', _formatPrice(s.open))),
                      Expanded(
                        child: _miniMetric(
                          '出来高',
                          _formatJapaneseShares(s.volume),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 開示情報
          _sectionCard(
            title: '開示情報',
            child: Column(
              children: [
                _infoRow('開示日', _dash(m.disclosedDate)),
                _infoRow('開示時刻', _dash(m.disclosedTime)),
                _infoRow('書類種別', _documentTypeJa(m.typeOfDocument)),
                _infoRow('対象期末', _dash(m.currentPeriodEndDate)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 決算サマリー
          _sectionCard(
            title: '決算サマリー',
            child: Column(
              children: [
                _infoRow('売上高', _formatJapaneseMoney(m.netSales)),
                _infoRow('営業利益', _formatJapaneseMoney(m.operatingProfit)),
                _infoRow('経常利益', _formatJapaneseMoney(m.ordinaryProfit)),
                _infoRow('純利益', _formatJapaneseMoney(m.profit)),
                _infoRow('EPS', _formatYen(m.earningsPerShare)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 業績予想
          _sectionCard(
            title: '会社予想',
            child: Column(
              children: [
                _infoRow('売上高予想', _formatJapaneseMoney(m.forecastNetSales)),
                _infoRow(
                  '営業利益予想',
                  _formatJapaneseMoney(m.forecastOperatingProfit),
                ),
                _infoRow(
                  '経常利益予想',
                  _formatJapaneseMoney(m.forecastOrdinaryProfit),
                ),
                _infoRow('純利益予想', _formatJapaneseMoney(m.forecastProfit)),
                _infoRow(
                  '年間配当予想',
                  _formatYen(m.annualDividendPerShareForecast),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBookCard() {
    final board = _orderBook;
    List<TradingOrder> _openOrders = [];
    bool _openOrdersLoading = false;

    return StockSectionCard(
      title: 'フル板',
      child: _orderBookLoading
          ? const Center(child: CircularProgressIndicator())
          : board == null
          ? const Text('板情報を取得できませんでした。')
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '売数量',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '気配値',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '買数量',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 売り板：高い価格を上、現在価格に近い価格を下
                ...board.sellBoard.reversed.map(
                  (row) => _orderBookRow(
                    price: row.price,
                    sellQuantity: row.quantity,
                    buyQuantity: null,
                    side: 'SELL',
                    onTap: () => _openOrderFromBoard(row.price),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFF93C5FD), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            const Text(
                              '現在価格',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '¥${board.currentPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFF93C5FD), thickness: 1),
                      ),
                    ],
                  ),
                ),

                // 買い板：現在価格に近い価格を上、安い価格を下
                ...board.buyBoard.map(
                  (row) => _orderBookRow(
                    price: row.price,
                    sellQuantity: null,
                    buyQuantity: row.quantity,
                    side: 'BUY',
                    onTap: () => _openOrderFromBoard(row.price),
                  ),
                ),
              ],
            ),
    );

  }

  Widget _buildOpenOrdersMiniCard() {
  return StockSectionCard(
    title: '注文中',
    child: _openOrdersLoading
        ? const Center(child: CircularProgressIndicator())
        : _openOrders.isEmpty
            ? const Text('未約定注文はありません。')
            : Column(
                children: [
                  ..._openOrders.take(3).map((o) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        o.stockName.isNotEmpty ? o.stockName : o.stockCode,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_orderSideLabel(o.side)} / ${_orderTypeLabel(o.orderType)} / ${o.quantity}株',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          await tradingRepository.cancelOrder(o.orderId);
                          await _loadOpenOrders();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('注文を取消しました。')),
                          );
                        },
                        child: const Text('取消'),
                      ),
                    );
                  }),
                  if (_openOrders.length > 3)
                    TextButton(
                      onPressed: () {
                        // context.go('/trading/orders');
                      },
                      child: Text('ほか${_openOrders.length - 3}件を表示'),
                    ),
                ],
              ),
  );
}

  String _orderSideLabel(String side) {
    return side == 'BUY' ? '買い' : '売り';
  }

  String _orderTypeLabel(String type) {
    switch (type) {
      case 'MARKET':
        return '成行';
      case 'LIMIT':
        return '指値';
      case 'STOP':
        return '逆指値';
      default:
        return type;
    }
  }

  Widget _orderBookRow({
    required double price,
    required int? sellQuantity,
    required int? buyQuantity,
    required String side,
    required VoidCallback onTap,
  }) {
    final isSell = side == 'SELL';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    final quantity = sellQuantity ?? buyQuantity ?? 0;
    final widthFactor = (quantity / 1000).clamp(0.08, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // 売数量
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  if (sellQuantity != null)
                    FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: widthFactor,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      sellQuantity == null ? '' : '${sellQuantity}株',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 22, color: const Color(0xFFE5E7EB)),

            // 価格
            SizedBox(
              width: 90,
              child: Text(
                '¥${price.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            Container(width: 1, height: 22, color: const Color(0xFFE5E7EB)),

            // 買数量
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (buyQuantity != null)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widthFactor,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      buyQuantity == null ? '' : '${buyQuantity}株',
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

  Widget _buildTradeButtons(StockDetailSummary s) {
    final canTrade = s.price > 0;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: canTrade
                ? () async {
                    final result = await showOrderDialog(
                      context: context,
                      stockCode: s.code,
                      stockName: s.name,
                      currentPrice: s.price,
                      initialSide: 'BUY',
                    );

                    if (!context.mounted || result == null) return;

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));

                    _loadOrderBook(s);
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('買う'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canTrade
                ? () async {
                    final result = await showOrderDialog(
                      context: context,
                      stockCode: s.code,
                      stockName: s.name,
                      currentPrice: s.price,
                      initialSide: 'SELL',
                    );

                    if (!context.mounted || result == null) return;

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));

                    _loadOrderBook(s);
                  }
                : null,
            icon: const Icon(Icons.sell_outlined),
            label: const Text('売る'),
          ),
        ),
      ],
    );
  }

  Widget _miniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _dash(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value;
  }

  String _formatPrice(double value) {
    if (value == 0) return '-';
    return value.toStringAsFixed(0);
  }

  Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _textOrDash(String? value) {
    return (value == null || value.isEmpty) ? '-' : value;
  }

  String _numOrDash(num? value) {
    return value == null ? '-' : value.toStringAsFixed(0);
  }

  Widget _buildChartTab() {
    final points = _filteredChart();
    final ma5 = _movingAverage(points, 5);
    final ma25 = _movingAverage(points, 25);
    final rsi = _rsi14(points);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        StockSectionCard(
          title: '表示設定',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['1M', '3M', '6M', '1Y', 'ALL']
                    .map(
                      (range) => ChoiceChip(
                        label: Text(range),
                        selected: _selectedRange == range,
                        onSelected: (_) {
                          setState(() {
                            _selectedRange = range;
                            _touchedPriceIndex = null;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'candle', label: Text('ローソク足')),
                  ButtonSegment(value: 'line', label: Text('線グラフ')),
                ],
                selected: {_chartType},
                onSelectionChanged: (value) {
                  setState(() {
                    _chartType = value.first;
                    _touchedPriceIndex = null;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        StockSectionCard(
          title: '価格チャート',
          child: SizedBox(
            height: 280,
            child: points.length < 2
                ? const Center(child: Text('チャートデータがありません'))
                : _chartType == 'candle'
                ? _buildCandleChart(points)
                : _buildLineChart(points),
          ),
        ),

        const SizedBox(height: 12),

        StockSectionCard(
          title: '出来高',
          child: SizedBox(
            height: 150,
            child: points.length < 2
                ? const Center(child: Text('出来高データがありません'))
                : _buildVolumeChart(points),
          ),
        ),

        const SizedBox(height: 12),

        StockSectionCard(
          title: '移動平均線',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _legendDot(const Color(0xFF94A3B8), '終値'),
                  _legendDot(const Color(0xFFF59E0B), 'MA5'),
                  _legendDot(const Color(0xFF7C3AED), 'MA25'),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '短期の流れは MA5、より大きな流れは MA25 で確認します。',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: points.length < 2
                    ? const Center(child: Text('移動平均データがありません'))
                    : _buildMaChart(points, ma5, ma25),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        StockSectionCard(
          title: 'RSI（14）',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '70以上: 買われすぎ / 30以下: 売られすぎの目安',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: points.length < 15
                    ? const Center(child: Text('RSIデータがありません'))
                    : _buildRsiChart(points, rsi),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeChart(List<StockChartPoint> points) {
    final maxY = points.map((e) => e.volume).fold<double>(0, math.max) * 1.15;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _bottomTitleStep(points.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                final step = _bottomTitleStep(points.length);
                if (i % step != 0 && i != points.length - 1) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDateLabel(points[i].date),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCompactVolumeLabel(value),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            if (response == null || response.spot == null) {
              setState(() {
                _touchedPriceIndex = null;
              });
              return;
            }
            setState(() {
              _touchedPriceIndex = response.spot!.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final p = points[group.x.toInt()];
              return BarTooltipItem(
                '${_safeDateLabel(p.date)}\n'
                '出来高: ${_formatJapaneseShares(p.volume)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(points.length, (i) {
          final p = points[i];
          final rise = p.close >= p.open;
          final isSelected = _touchedPriceIndex == i;

          return BarChartGroupData(
            x: i,
            showingTooltipIndicators: isSelected ? const [0] : const [],
            barRods: [
              BarChartRodData(
                toY: p.volume,
                width: isSelected ? 8 : 6,
                color: rise ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(2),
                borderSide: isSelected
                    ? const BorderSide(color: Colors.black54, width: 1)
                    : BorderSide.none,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<StockChartPoint> points) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].close));
    }

    return LineChart(
      LineChartData(
        minY: points.map((e) => e.low).reduce(math.min) * 0.98,
        maxY: points.map((e) => e.high).reduce(math.max) * 1.02,
        gridData: const FlGridData(show: true),
        titlesData: _chartTitles(points),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            if (response == null ||
                response.lineBarSpots == null ||
                response.lineBarSpots!.isEmpty) {
              setState(() {
                _touchedPriceIndex = null;
              });
              return;
            }
            setState(() {
              _touchedPriceIndex = response.lineBarSpots!.first.x.toInt();
            });
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: const Color(0xFF64748B),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, i) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF2563EB),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final idx = spot.x.toInt();
                final p = points[idx];
                return LineTooltipItem(
                  '${_safeDateLabel(p.date)}\n'
                  '始値: ${_formatYen(p.open)}\n'
                  '高値: ${_formatYen(p.high)}\n'
                  '安値: ${_formatYen(p.low)}\n'
                  '終値: ${_formatYen(p.close)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.04,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            spots: spots,
            barWidth: 2.5,
            color: const Color(0xFF2563EB),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMaChart(
    List<StockChartPoint> points,
    List<double?> ma5,
    List<double?> ma25,
  ) {
    final closeSpots = <FlSpot>[];
    final ma5Spots = <FlSpot>[];
    final ma25Spots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      closeSpots.add(FlSpot(i.toDouble(), points[i].close));
      if (ma5[i] != null) {
        ma5Spots.add(FlSpot(i.toDouble(), ma5[i]!));
      }
      if (ma25[i] != null) {
        ma25Spots.add(FlSpot(i.toDouble(), ma25[i]!));
      }
    }

    return LineChart(
      LineChartData(
        minY: points.map((e) => e.low).reduce(math.min) * 0.98,
        maxY: points.map((e) => e.high).reduce(math.max) * 1.02,
        gridData: const FlGridData(show: true),
        titlesData: _chartTitles(points),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            if (response == null ||
                response.lineBarSpots == null ||
                response.lineBarSpots!.isEmpty) {
              setState(() {
                _touchedMaIndex = null;
              });
              return;
            }
            setState(() {
              _touchedMaIndex = response.lineBarSpots!.first.x.toInt();
            });
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: const Color(0xFF64748B),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, i) {
                    return FlDotCirclePainter(
                      radius: 3.5,
                      color: bar.color ?? Colors.blue,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label = '終値';
                if (spot.barIndex == 1) label = 'MA5';
                if (spot.barIndex == 2) label = 'MA25';

                return LineTooltipItem(
                  '$label: ${_formatYen(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            spots: closeSpots,
            barWidth: 1.5,
            color: const Color(0xFF94A3B8),
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            isCurved: false,
            spots: ma5Spots,
            barWidth: 2.0,
            color: const Color(0xFFF59E0B),
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            isCurved: false,
            spots: ma25Spots,
            barWidth: 2.0,
            color: const Color(0xFF7C3AED),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildRsiChart(List<StockChartPoint> points, List<double?> rsi) {
    final rsiSpots = <FlSpot>[];
    for (int i = 0; i < rsi.length; i++) {
      if (rsi[i] != null) {
        rsiSpots.add(FlSpot(i.toDouble(), rsi[i]!));
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true),
        titlesData: _chartTitles(points),
        borderData: FlBorderData(show: true),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 70,
              color: Colors.redAccent,
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                labelResolver: (_) => '70',
              ),
            ),
            HorizontalLine(
              y: 50,
              color: Colors.black26,
              strokeWidth: 1,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(fontSize: 10, color: Colors.black45),
                labelResolver: (_) => '50',
              ),
            ),
            HorizontalLine(
              y: 30,
              color: Colors.green,
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 6, top: 2),
                style: const TextStyle(fontSize: 10, color: Colors.green),
                labelResolver: (_) => '30',
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            if (response == null ||
                response.lineBarSpots == null ||
                response.lineBarSpots!.isEmpty) {
              setState(() {
                _touchedRsiIndex = null;
              });
              return;
            }
            setState(() {
              _touchedRsiIndex = response.lineBarSpots!.first.x.toInt();
            });
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: const Color(0xFF64748B),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, i) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF0F766E),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final date = (idx >= 0 && idx < points.length)
                    ? _safeDateLabel(points[idx].date)
                    : '';
                return LineTooltipItem(
                  '$date\nRSI: ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            spots: rsiSpots,
            barWidth: 2,
            color: const Color(0xFF0F766E),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCandleChart(List<StockChartPoint> points) {
    final minY = points.map((e) => e.low).reduce(math.min) * 0.98;
    final maxY = points.map((e) => e.high).reduce(math.max) * 1.02;

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true),
        titlesData: _chartTitles(points),
        borderData: FlBorderData(show: true),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (!mounted) return;
            if (response == null || response.spot == null) {
              setState(() {
                _touchedPriceIndex = null;
              });
              return;
            }
            setState(() {
              _touchedPriceIndex = response.spot!.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rodIndex != 1) return null;

              final p = points[group.x.toInt()];

              return BarTooltipItem(
                '${_safeDateLabel(p.date)}\n'
                '始値: ${_formatYen(p.open)}\n'
                '高値: ${_formatYen(p.high)}\n'
                '安値: ${_formatYen(p.low)}\n'
                '終値: ${_formatYen(p.close)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.04,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(points.length, (i) {
          final p = points[i];
          final rise = p.close >= p.open;
          final color = rise
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626);
          final isSelected = _touchedPriceIndex == i;

          return BarChartGroupData(
            x: i,
            showingTooltipIndicators: isSelected ? const [1] : const [],
            barRods: [
              BarChartRodData(
                fromY: p.low,
                toY: p.high,
                width: 2,
                color: color,
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                fromY: math.min(p.open, p.close),
                toY: math.max(p.open, p.close),
                width: isSelected ? 10 : 8,
                color: color,
                borderRadius: BorderRadius.circular(1),
                borderSide: isSelected
                    ? const BorderSide(color: Colors.black54, width: 1)
                    : BorderSide.none,
              ),
            ],
          );
        }),
      ),
    );
  }

  FlTitlesData _chartTitles(List<StockChartPoint> points) {
    final step = _bottomTitleStep(points.length);

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            return Text(
              _priceAxisLabel(value),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: step.toDouble(),
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= points.length) {
              return const SizedBox.shrink();
            }
            if (i % step != 0 && i != points.length - 1) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _shortDateLabel(points[i].date),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_newsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visibleNews.isEmpty) {
      return const Center(child: Text('ニュースはまだありません'));
    }

    return ListView.separated(
      itemCount: _visibleNews.length + (_hasMoreOlderNews ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == _visibleNews.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: _appendOlderNews,
                child: const Text('さらに過去のニュースを表示'),
              ),
            ),
          );
        }

        final n = _visibleNews[i];
        final isRead = _readNewsKeys.contains(n.readKey);

        return ListTile(
          contentPadding: const EdgeInsets.all(12),
          title: Text(
            n.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRead ? Colors.black38 : Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${n.source}  ${n.publishedAt}',
              style: TextStyle(color: isRead ? Colors.black38 : Colors.black54),
            ),
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: isRead ? Colors.black38 : Colors.black54,
          ),
          onTap: () async {
            await _markNewsAsRead(n);
            await _openUrl(n.link);
          },
        );
      },
    );
  }

  Widget _buildCompanyTab() {
    final c = _company;
    final s = _summary!;

    final companyName = c?.companyName.isNotEmpty == true
        ? c!.companyName
        : s.name;
    final market = c?.market.isNotEmpty == true ? c!.market : s.market;
    final industry = c?.industry.isNotEmpty == true ? c!.industry : s.industry;

    final mapQuery = c?.mapQuery.isNotEmpty == true
        ? c!.mapQuery
        : (companyName.isNotEmpty ? '$companyName 本社' : widget.code);

    final trendsKeyword = c?.trendsKeyword.isNotEmpty == true
        ? c!.trendsKeyword
        : (companyName.isNotEmpty ? companyName : widget.code);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        StockSectionCard(
          title: '企業情報',
          child: Column(
            children: [
              _kv('企業名', companyName),
              _kv('市場', market),
              _kv('業種', industry),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: '概要',
          child: Text(
            c?.description.isNotEmpty == true
                ? c!.description
                : '企業概要データはまだ登録されていません。',
            style: const TextStyle(height: 1.6),
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: 'Webサイト',
          child: InkWell(
            onTap: c?.website.isNotEmpty == true
                ? () => _openUrl(c!.website)
                : null,
            child: Text(
              c?.website.isNotEmpty == true ? c!.website : '-',
              style: TextStyle(
                color: c?.website.isNotEmpty == true
                    ? const Color(0xFF2563EB)
                    : Colors.black54,
                decoration: c?.website.isNotEmpty == true
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: 'マップ / トレンド',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => _openUrl(_buildGoogleMapsUrl(mapQuery)),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Googleマップで見る'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openUrl(_buildGoogleTrendsUrl(trendsKeyword)),
                icon: const Icon(Icons.trending_up),
                label: const Text('Google Trendsで見る'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradingTab() {
    final s = _summary;

    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        StockSectionCard(
          title: '売買',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _metricHeaderBox(
                '現在価格',
                s.price > 0 ? '¥${s.price.toStringAsFixed(0)}' : '-',
              ),
              const SizedBox(height: 14),
              _buildTradeButtons(s),
              const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: s.price > 0
                      ? () async {
                          final result = await showAlgoOrderDialog(
                            context: context,
                            stockCode: s.code,
                            stockName: s.name,
                            currentPrice: s.price,
                          );

                          if (!mounted || result == null) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message)),
                          );

                          await _loadOpenOrders();
                        }
                      : null,
                  icon: const Icon(Icons.auto_graph),
                  label: const Text('アルゴ注文'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildOrderBookCard(),
        const SizedBox(height: 12),
        _buildOpenOrdersMiniCard(),
      ],
    );
  }

  @override
  void dispose() {
    _newsScrollController.dispose();
    _tabController.dispose();
    repository.dispose();
    favoriteApiRepository.dispose();
    newsRepo.dispose();
    tradingRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.code),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const StockLoadingView();
          }

          if (_error != null || _summary == null) {
            return StockErrorView(
              title: '詳細データの取得に失敗しました',
              message: _error ?? '不明なエラー',
              onRetry: _load,
            );
          }

          return Column(
            children: [
              _buildHeader(),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: const Color(0xFF2563EB),
                  tabs: const [
                    Tab(text: '概要'),
                    Tab(text: 'チャート'),
                    Tab(text: 'ニュース'),
                    Tab(text: '企業情報'),
                    Tab(text: '売買'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildChartTab(),
                    _buildNewsTab(),
                    _buildCompanyTab(),
                    _buildTradingTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
