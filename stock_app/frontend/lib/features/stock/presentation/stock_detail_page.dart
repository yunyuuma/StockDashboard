import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/favorite_api_repository.dart';
import '../data/stock_detail_api_repository.dart';
import '../data/stock_news_api_repository.dart';
import '../data/stock_news.dart';
import '../domain/app_session.dart';
import '../domain/stock_detail_models.dart';
import 'components/stock_error_view.dart';
import 'components/stock_loading_view.dart';
import 'components/stock_section_card.dart';

class StockDetailPage extends StatefulWidget {
  const StockDetailPage({
    super.key,
    required this.code,
  });

  final String code;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage>
    with SingleTickerProviderStateMixin {
  final StockDetailApiRepository repository = StockDetailApiRepository();
  final FavoriteApiRepository favoriteApiRepository = FavoriteApiRepository();
  final StockNewsApiRepository newsRepo = StockNewsApiRepository();

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
    _tabController = TabController(length: 4, vsync: this);
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
        favoriteApiRepository.fetchFavorites(userId: AppSession.userId),
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

      final sortedNews = [...news]..sort((a, b) {
        final ad = _parseNewsDate(a.publishedAt);
        final bd = _parseNewsDate(b.publishedAt);
        return bd.compareTo(ad);
      });

      setState(() {
        _summary = summary;
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
          userId: AppSession.userId,
          stockCode: widget.code,
        );
      } else {
        await favoriteApiRepository.addFavorite(
          userId: AppSession.userId,
          stockCode: widget.code,
        );
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入り更新に失敗しました: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
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
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
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
    final s = _summary!;
    final m = _metrics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        StockSectionCard(
          title: '当日データ',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _infoTile('現在価格', s.price > 0 ? '¥${s.price.toStringAsFixed(0)}' : '-')),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('前日比', '${s.changePct >= 0 ? '+' : ''}${s.changePct.toStringAsFixed(2)}%')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('始値', s.open > 0 ? '¥${s.open.toStringAsFixed(0)}' : '-')),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('高値', s.high > 0 ? '¥${s.high.toStringAsFixed(0)}' : '-')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('安値', s.low > 0 ? '¥${s.low.toStringAsFixed(0)}' : '-')),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('出来高', s.volume > 0 ? s.volume.toStringAsFixed(0) : '-')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: '開示サマリー',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _infoTile('開示日', _textOrDash(m?.disclosedDate))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('開示時刻', _textOrDash(m?.disclosedTime))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('書類種別', _textOrDash(m?.typeOfDocument))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('対象期間', _textOrDash(m?.currentPeriodEndDate))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: '決算サマリー',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _infoTile('売上高', _numOrDash(m?.netSales))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('営業利益', _numOrDash(m?.operatingProfit))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('経常利益', _numOrDash(m?.ordinaryProfit))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('当期純利益', _numOrDash(m?.profit))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('EPS', _numOrDash(m?.earningsPerShare))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('年間配当予想', _numOrDash(m?.annualDividendPerShareForecast))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: '業績予想',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _infoTile('売上高予想', _numOrDash(m?.forecastNetSales))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('営業利益予想', _numOrDash(m?.forecastOperatingProfit))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _infoTile('経常利益予想', _numOrDash(m?.forecastOrdinaryProfit))),
                  const SizedBox(width: 10),
                  Expanded(child: _infoTile('当期純利益予想', _numOrDash(m?.forecastProfit))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
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
                children: ['1M', '3M', '6M', '1Y', 'ALL']
                    .map(
                      (range) => ChoiceChip(
                        label: Text(range),
                        selected: _selectedRange == range,
                        onSelected: (_) {
                          setState(() {
                            _selectedRange = range;
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
          title: '移動平均線（MA5 / MA25）',
          child: SizedBox(
            height: 220,
            child: points.length < 2
                ? const Center(child: Text('移動平均データがありません'))
                : _buildMaChart(points, ma5, ma25),
          ),
        ),
        const SizedBox(height: 12),
        StockSectionCard(
          title: 'RSI（14）',
          child: SizedBox(
            height: 180,
            child: points.length < 15
                ? const Center(child: Text('RSIデータがありません'))
                : _buildRsiChart(points, rsi),
          ),
        ),
      ],
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
            HorizontalLine(y: 70, color: Colors.redAccent, strokeWidth: 1),
            HorizontalLine(y: 30, color: Colors.green, strokeWidth: 1),
          ],
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
        barGroups: List.generate(points.length, (i) {
          final p = points[i];
          final rise = p.close >= p.open;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: p.low,
                toY: p.high,
                width: 2,
                color: rise ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              BarChartRodData(
                fromY: math.min(p.open, p.close),
                toY: math.max(p.open, p.close),
                width: 8,
                color: rise ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ],
          );
        }),
      ),
    );
  }

  FlTitlesData _chartTitles(List<StockChartPoint> points) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 44),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: math.max(1, (points.length / 4).floor()).toDouble(),
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= points.length) {
              return const SizedBox.shrink();
            }
            final date = points[i].date;
            final short = date.length >= 10 ? date.substring(5, 10) : date;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                short,
                style: const TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_newsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_visibleNews.isEmpty) {
      return const Center(
        child: Text('ニュースはまだありません'),
      );
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
              style: TextStyle(
                color: isRead ? Colors.black38 : Colors.black54,
              ),
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

  final companyName =
      c?.companyName.isNotEmpty == true ? c!.companyName : s.name;
  final market =
      c?.market.isNotEmpty == true ? c!.market : s.market;
  final industry =
      c?.industry.isNotEmpty == true ? c!.industry : s.industry;

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

  @override
  void dispose() {
    _newsScrollController.dispose();
    _tabController.dispose();
    repository.dispose();
    favoriteApiRepository.dispose();
    newsRepo.dispose();
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