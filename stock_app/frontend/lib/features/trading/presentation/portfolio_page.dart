import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/portfolio_repository.dart';
import '../domain/portfolio_models.dart';
import '../../ai/data/ai_advisor_repository.dart';
import '../../ai/domain/ai_portfolio_models.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final PortfolioRepository _repository = PortfolioRepository();
  final AiAdvisorRepository _aiRepository = AiAdvisorRepository();
  bool _loading = true;
  String? _error;
  PortfolioSummary? _summary;
  AiPortfolioAdvisor? _aiAdvisor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _repository.dispose();
    _aiRepository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _repository.fetchPortfolio();
      final advisor = await _aiRepository.fetchPortfolioAdvisor();

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _aiAdvisor = advisor;
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

  String _yen(double value) => '¥${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final aiAdvisor = _aiAdvisor;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ポートフォリオ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/trading'),
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
        builder: (_) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (summary == null) {
            return const Center(child: Text('ポートフォリオデータがありません。'));
          }

          final isPlus = summary.profitLoss >= 0;
          final pnlColor =
              isPlus ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

          final dailyIsPlus = summary.dailyProfitLoss >= 0;
          final dailyColor =
              dailyIsPlus ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '総資産',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _yen(summary.totalAsset),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${isPlus ? '+' : ''}${_yen(summary.profitLoss)} / ${isPlus ? '+' : ''}${summary.profitLossRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: '仮想残高',
                      value: _yen(summary.cash),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: '保有評価額',
                      value: _yen(summary.stockValue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: '日次損益',
                      value:
                          '${dailyIsPlus ? '+' : ''}${_yen(summary.dailyProfitLoss)}',
                      subValue:
                          '${dailyIsPlus ? '+' : ''}${summary.dailyProfitLossRate.toStringAsFixed(2)}%',
                      valueColor: dailyColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: '最大DD',
                      value: '-${_yen(summary.maxDrawdown)}',
                      subValue:
                          '-${summary.maxDrawdownRate.toStringAsFixed(2)}%',
                      valueColor: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '資産推移',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                        if (aiAdvisor != null) ...[
                            _AiPortfolioCard(
                              advisor: aiAdvisor,
                            ),
                            const SizedBox(height: 16),
                          ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: summary.points.length < 2
                            ? const Center(child: Text('資産推移データがありません。'))
                            : _buildAssetChart(summary.points),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'セクター比率',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      summary.sectorAllocations.isEmpty
                          ? const SizedBox(
                              height: 120,
                              child: Center(child: Text('保有銘柄がありません。')),
                            )
                          : SizedBox(
                              height: 260,
                              child: _buildSectorPieChart(
                                summary.sectorAllocations,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssetChart(List<PortfolioPoint> points) {
    final totalSpots = <FlSpot>[];
    final cashSpots = <FlSpot>[];
    final stockSpots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      totalSpots.add(FlSpot(i.toDouble(), points[i].totalAsset));
      cashSpots.add(FlSpot(i.toDouble(), points[i].cash));
      stockSpots.add(FlSpot(i.toDouble(), points[i].marketValue));
    }

    final values = <double>[
      ...points.map((e) => e.totalAsset),
      ...points.map((e) => e.cash),
      ...points.map((e) => e.marketValue),
    ];

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final minY = minValue == maxValue ? minValue * 0.95 : minValue * 0.98;
    final maxY = minValue == maxValue ? maxValue * 1.05 : maxValue * 1.02;

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(label: '総資産', color: Color(0xFF2563EB)),
            SizedBox(width: 14),
            _LegendDot(label: '現金', color: Color(0xFF64748B)),
            SizedBox(width: 14),
            _LegendDot(label: '株式時価', color: Color(0xFF16A34A)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) {
                  if (items.isEmpty) {
                    return [];
                  }

                  final first = items.first;
                  final index = first.x.toInt();

                  if (index < 0 || index >= points.length) {
                    return items.map((_) => null).toList();
                  }

                  final p = points[index];

                  final tooltip = LineTooltipItem(
                    '${p.eventLabel}\n'
                    '総資産 ${_yen(p.totalAsset)}\n'
                    '現金 ${_yen(p.cash)}\n'
                    '株式 ${_yen(p.marketValue)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );

                  return items.asMap().entries.map((entry) {
                    if (entry.key == 0) {
                      return tooltip;
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
              lineBarsData: [
                LineChartBarData(
                  spots: totalSpots,
                  isCurved: false,
                  barWidth: 3,
                  color: const Color(0xFF2563EB),
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: cashSpots,
                  isCurved: false,
                  barWidth: 2,
                  color: const Color(0xFF64748B),
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: stockSpots,
                  isCurved: false,
                  barWidth: 2,
                  color: const Color(0xFF16A34A),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectorPieChart(List<SectorAllocation> sectors) {
    final shown = sectors.take(6).toList();

    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: shown.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;

                return PieChartSectionData(
                  value: s.rate,
                  title: '${s.rate.toStringAsFixed(1)}%',
                  radius: 48,
                  color: _sectorColor(index),
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: shown.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _sectorColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.sector,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${s.rate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _sectorColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFDC2626),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
    ];

    return colors[index % colors.length];
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    this.subValue,
    this.valueColor,
  });

  final String title;
  final String value;
  final String? subValue;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: valueColor ?? Colors.black87,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: valueColor ?? Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiPortfolioCard extends StatelessWidget {
  const _AiPortfolioCard({
    required this.advisor,
  });

  final AiPortfolioAdvisor advisor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy_outlined),
                SizedBox(width: 8),
                Text(
                  'AIポートフォリオ診断',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              advisor.summary,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            _section('強み', advisor.strengths),
            _section('リスク', advisor.risks),
            _section('改善提案', advisor.suggestions),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}