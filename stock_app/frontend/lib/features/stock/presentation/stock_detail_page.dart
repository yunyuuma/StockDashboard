import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/company_repository.dart';
import '../data/price_repository.dart';
import '../domain/company.dart';

class StockDetailPage extends StatefulWidget {
  final String code;

  const StockDetailPage({
    super.key,
    required this.code,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final CompanyRepository _repo = CompanyRepository();
  final PriceRepository _priceRepo =
      PriceRepository(proxyBaseUrl: 'https://workers.gikiin67.workers.dev');

  Company? _company;
  List<HistoryPoint> _history = [];

  bool _loading = true;
  bool _historyLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _priceRepo.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _repo.fetchAll();

      final baseCompany = list.firstWhere(
        (x) => x.code == widget.code,
        orElse: () => Company(
          code: widget.code,
          name: '',
          kana: '',
          market: '',
          industry: '',
          price: 0,
          changePct: 0,
          marketCap: 0,
          volume: 0,
          favorite: false,
        ),
      );

      Company company = baseCompany;

      try {
        final quotes = await _priceRepo.refreshQuotes([widget.code]);
        final q = quotes[widget.code];
        if (q != null) {
          company = company.copyWith(
            price: q.price,
            changePct: q.changePct,
          );
        }
      } catch (e) {
        debugPrint('price load error: $e');
      }

      await _loadHistory();

      // 履歴の最新出来高を company.volume に反映
      if (_history.isNotEmpty) {
        final latest = _history.last;
        company = company.copyWith(
          volume: latest.volume,
        );
      }

      if (!mounted) return;

      setState(() {
        _company = company;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    _historyLoading = true;

    try {
      final uri = Uri.parse(
        'https://workers.gikiin67.workers.dev/stock-history',
      ).replace(
        queryParameters: {'code': widget.code},
      );

      final res = await http.get(uri, headers: {
        'Accept': 'application/json,text/plain,*/*',
      });

      if (res.statusCode != 200) {
        throw Exception('history fetch failed: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final points = (decoded['points'] as List?) ?? const [];

      _history = points.map((e) {
        final m = e as Map<String, dynamic>;
        return HistoryPoint(
          date: (m['date'] ?? '').toString(),
          open: ((m['open'] ?? 0) as num).toDouble(),
          high: ((m['high'] ?? 0) as num).toDouble(),
          low: ((m['low'] ?? 0) as num).toDouble(),
          close: ((m['close'] ?? 0) as num).toDouble(),
          volume: ((m['volume'] ?? 0) as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('history load error: $e');
      _history = [];
    } finally {
      _historyLoading = false;
    }
  }

  List<double> _buildMiniChartData() {
    if (_history.isNotEmpty) {
      final sampled = <double>[];
      final step = _history.length > 20 ? (_history.length / 20).ceil() : 1;
      for (int i = 0; i < _history.length; i += step) {
        sampled.add(_history[i].close);
      }
      if (sampled.isEmpty || sampled.last != _history.last.close) {
        sampled.add(_history.last.close);
      }
      return sampled;
    }

    final base = (_company?.price ?? 0) <= 0 ? 1000.0 : _company!.price;
    return [
      (base * 0.96).toDouble(),
      (base * 0.98).toDouble(),
      (base * 0.97).toDouble(),
      (base * 1.01).toDouble(),
      (base * 1.03).toDouble(),
      (base * 1.00).toDouble(),
      base.toDouble(),
    ];
  }

  List<NewsItem> _buildDemoNews(Company company) {
    return [
      NewsItem(
        title: '${company.name.isEmpty ? company.code : company.name} の最新動向に注目',
        source: 'デモニュース',
        date: '2026-03-10',
      ),
      NewsItem(
        title: '${company.industry.isEmpty ? '業界' : company.industry} の市場環境まとめ',
        source: 'デモニュース',
        date: '2026-03-09',
      ),
      NewsItem(
        title: '${company.code} の株価推移と投資家の注目点',
        source: 'デモニュース',
        date: '2026-03-08',
      ),
    ];
  }

  Future<void> _refreshPage() async {
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.code),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '読み込み失敗: $_error',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadAll,
                  child: Text('リトライ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final company = _company!;
    final news = _buildDemoNews(company);

    final changeAmount = company.price * company.changePct / 100;
    final isPlus = company.changePct >= 0;
    final changeColor = isPlus ? Colors.red : Colors.blue;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                title: Text(
                  company.name.isEmpty
                      ? company.code
                      : '${company.code} ${company.name}',
                ),
                actions: [
                  Icon(Icons.star_border),
                  SizedBox(width: 12),
                  Icon(Icons.share_outlined),
                  SizedBox(width: 12),
                  Icon(Icons.notifications_none),
                  SizedBox(width: 12),
                ],
                bottom: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: '概要'),
                    Tab(text: 'チャート'),
                    Tab(text: 'ニュース'),
                    Tab(text: '指標'),
                    Tab(text: '企業情報'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¥${company.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${isPlus ? '+' : ''}${changeAmount.toStringAsFixed(0)} (${company.changePct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${company.market} / ${company.industry}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: _refreshPage,
                child: _OverviewTab(
                  company: company,
                  miniChartData: _buildMiniChartData(),
                  news: news,
                ),
              ),
              RefreshIndicator(
                onRefresh: _refreshPage,
                child: _ChartTab(
                  history: _history,
                  loading: _historyLoading,
                ),
              ),
              _NewsTab(news: news),
              _IndicatorTab(company: company),
              _CompanyTab(company: company),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Company company;
  final List<double> miniChartData;
  final List<NewsItem> news;

  const _OverviewTab({
    required this.company,
    required this.miniChartData,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    final isPlus = company.changePct >= 0;
    final color = isPlus ? Colors.red : Colors.blue;

    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'ミニチャート',
          child: SizedBox(
            height: 160,
            child: _MiniChart(
              data: miniChartData,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: '株価指標',
          child: Row(
            children: [
              _Kpi(
                label: '株価',
                value: '¥${company.price.toStringAsFixed(0)}',
              ),
              SizedBox(width: 12),
              _Kpi(
                label: '前日比',
                value:
                    '${isPlus ? '+' : ''}${company.changePct.toStringAsFixed(2)}%',
                valueColor: color,
              ),
              SizedBox(width: 12),
              _Kpi(
                label: '出来高',
                value: company.volume > 0
                    ? company.volume.toStringAsFixed(0)
                    : '未取得',
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: '企業情報',
          child: Column(
            children: [
              _Info(label: '市場', value: company.market),
              Divider(height: 20),
              _Info(label: '業種', value: company.industry),
            ],
          ),
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: '関連ニュース',
          child: Column(
            children: news.take(3).map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _NewsCard(item: item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

enum ChartRange { m1, m6, y1, y2 }

class _ChartTab extends StatefulWidget {
  final List<HistoryPoint> history;
  final bool loading;

  const _ChartTab({
    required this.history,
    required this.loading,
  });

  @override
  State<_ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<_ChartTab> {
  ChartRange _range = ChartRange.y2;

  List<HistoryPoint> _filteredHistory(List<HistoryPoint> history) {
    if (history.isEmpty) return [];

    final now = DateTime.now();
    late DateTime from;

    switch (_range) {
      case ChartRange.m1:
        from = DateTime(now.year, now.month - 1, now.day);
        break;
      case ChartRange.m6:
        from = DateTime(now.year, now.month - 6, now.day);
        break;
      case ChartRange.y1:
        from = DateTime(now.year - 1, now.month, now.day);
        break;
      case ChartRange.y2:
        from = DateTime(now.year - 2, now.month, now.day);
        break;
    }

    final filtered = history.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return false;
      return !d.isBefore(from);
    }).toList();

    return filtered.isEmpty ? history : filtered;
  }

  List<FlSpot> _movingAverage(List<HistoryPoint> data, int period) {
    if (data.length < period) return [];

    final spots = <FlSpot>[];

    for (int i = period - 1; i < data.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += data[j].close;
      }
      final avg = sum / period;
      spots.add(FlSpot(i.toDouble(), avg));
    }

    return spots;
  }

  Widget _rangeChip(String label, ChartRange range) {
    return ChoiceChip(
      label: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(label),
      ),
      selected: _range == range,
      shape: StadiumBorder(),
      onSelected: (_) {
        setState(() {
          _range = range;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (widget.history.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 240),
          Center(child: Text('2年チャートのデータがありません')),
        ],
      );
    }

    final history = _filteredHistory(widget.history);

    final minPrice = history.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        history.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final maxVolume =
        history.map((e) => e.volume).reduce((a, b) => a > b ? a : b);

    final interval = ((maxPrice - minPrice) / 4).abs();
    final safeInterval = interval == 0 ? 1.0 : interval;

    final candleSpots = List.generate(history.length, (i) {
      final h = history[i];
      return CandlestickSpot(
        x: i.toDouble(),
        open: h.open,
        high: h.high,
        low: h.low,
        close: h.close,
      );
    });

    final ma5 = _movingAverage(history, 5);
    final ma25 = _movingAverage(history, 25);
    final ma75 = _movingAverage(history, 75);

    final volumeGroups = List.generate(history.length, (i) {
      final h = history[i];
      final up = h.close >= h.open;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: h.volume,
            width: 4,
            color: up
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.blue.withValues(alpha: 0.7),
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });

    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: '株価チャート',
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _rangeChip('1M', ChartRange.m1),
                  _rangeChip('6M', ChartRange.m6),
                  _rangeChip('1Y', ChartRange.y1),
                  _rangeChip('2Y', ChartRange.y2),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendDot(color: Colors.orange, label: 'MA5'),
                  _LegendDot(color: Colors.green, label: 'MA25'),
                  _LegendDot(color: Colors.purple, label: 'MA75'),
                ],
              ),
              SizedBox(height: 16),

              // ローソク足
              SizedBox(
                height: 300,
                child: CandlestickChart(
                  CandlestickChartData(
                    minY: minPrice * 0.98,
                    maxY: maxPrice * 1.02,
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: safeInterval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: safeInterval,
                    ),
                    candlestickSpots: candleSpots,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 移動平均線
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: minPrice * 0.98,
                    maxY: maxPrice * 1.02,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: safeInterval,
                    ),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: safeInterval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: ma5,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: ma25,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: ma75,
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 出来高
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxVolume * 1.1,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return SizedBox.shrink();
                            return Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: volumeGroups,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewsTab extends StatelessWidget {
  final List<NewsItem> news;

  const _NewsTab({
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: news.length,
      separatorBuilder: (_, _) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _NewsCard(item: news[index]);
      },
    );
  }
}

class _IndicatorTab extends StatelessWidget {
  final Company company;

  const _IndicatorTab({
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: '指標',
          child: Column(
            children: [
              _Info(
                label: '時価総額',
                value: company.marketCap > 0
                    ? company.marketCap.toStringAsFixed(0)
                    : '未取得',
              ),
              Divider(height: 20),
              _Info(
                label: '出来高',
                value: company.volume > 0
                    ? company.volume.toStringAsFixed(0)
                    : '未取得',
              ),
              Divider(height: 20),
              _Info(label: 'PER', value: '今後追加'),
              Divider(height: 20),
              _Info(label: 'PBR', value: '今後追加'),
              Divider(height: 20),
              _Info(label: '配当利回り', value: '今後追加'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyTab extends StatelessWidget {
  final Company company;

  const _CompanyTab({
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: '企業情報',
          child: Column(
            children: [
              _Info(label: '企業名', value: company.name),
              Divider(height: 20),
              _Info(label: '市場', value: company.market),
              Divider(height: 20),
              _Info(label: '業種', value: company.industry),
              Divider(height: 20),
              _Info(label: 'ティッカー', value: company.code),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _MiniChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i]),
            ),
            isCurved: true,
            color: color,
            dotData: FlDotData(show: false),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Kpi({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;

  const _NewsCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('${item.source}  ・  ${item.date}'),
        ),
        trailing: Icon(Icons.open_in_new, size: 18),
      ),
    );
  }
}

class HistoryPoint {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  HistoryPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class NewsItem {
  final String title;
  final String source;
  final String date;

  NewsItem({
    required this.title,
    required this.source,
    required this.date,
  });
}