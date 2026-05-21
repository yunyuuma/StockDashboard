class PortfolioSummary {
  final double cash;
  final double stockValue;
  final double totalAsset;
  final double profitLoss;
  final double profitLossRate;

  final double dailyProfitLoss;
  final double dailyProfitLossRate;
  final double maxDrawdown;
  final double maxDrawdownRate;

  final List<PortfolioPoint> points;
  final List<SectorAllocation> sectorAllocations;

  const PortfolioSummary({
    required this.cash,
    required this.stockValue,
    required this.totalAsset,
    required this.profitLoss,
    required this.profitLossRate,
    required this.dailyProfitLoss,
    required this.dailyProfitLossRate,
    required this.maxDrawdown,
    required this.maxDrawdownRate,
    required this.points,
    required this.sectorAllocations,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      cash: _toDouble(json['cash']),
      stockValue: _toDouble(json['stockValue']),
      totalAsset: _toDouble(json['totalAsset']),
      profitLoss: _toDouble(json['profitLoss']),
      profitLossRate: _toDouble(json['profitLossRate']),
      dailyProfitLoss: _toDouble(json['dailyProfitLoss']),
      dailyProfitLossRate: _toDouble(json['dailyProfitLossRate']),
      maxDrawdown: _toDouble(json['maxDrawdown']),
      maxDrawdownRate: _toDouble(json['maxDrawdownRate']),
      points: ((json['points'] ?? []) as List)
          .map((e) => PortfolioPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      sectorAllocations: ((json['sectorAllocations'] ?? []) as List)
          .map((e) => SectorAllocation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PortfolioPoint {
  final String? dateTime;
  final double cash;
  final double stockValue;
  final double marketValue;
  final double totalAsset;
  final String eventLabel;

  const PortfolioPoint({
    required this.dateTime,
    required this.cash,
    required this.stockValue,
    required this.marketValue,
    required this.totalAsset,
    required this.eventLabel,
  });

  factory PortfolioPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioPoint(
      dateTime: json['dateTime']?.toString(),
      cash: _toDouble(json['cash']),
      stockValue: _toDouble(json['stockValue']),
      marketValue: _toDouble(json['marketValue'] ?? json['stockValue']),
      totalAsset: _toDouble(json['totalAsset']),
      eventLabel: (json['eventLabel'] ?? '').toString(),
    );
  }
}

class SectorAllocation {
  final String sector;
  final double amount;
  final double rate;

  const SectorAllocation({
    required this.sector,
    required this.amount,
    required this.rate,
  });

  factory SectorAllocation.fromJson(Map<String, dynamic> json) {
    return SectorAllocation(
      sector: (json['sector'] ?? '未設定').toString(),
      amount: _toDouble(json['amount']),
      rate: _toDouble(json['rate']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}