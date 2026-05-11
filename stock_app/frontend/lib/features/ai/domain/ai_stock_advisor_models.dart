class AiStockAdvisorResult {
  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final String riskLevel;
  final String summary;
  final List<String> analysis;
  final List<String> checkPoints;
  final List<String> warnings;

  const AiStockAdvisorResult({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.riskLevel,
    required this.summary,
    required this.analysis,
    required this.checkPoints,
    required this.warnings,
  });

  factory AiStockAdvisorResult.fromJson(Map<String, dynamic> json) {
    return AiStockAdvisorResult(
      stockCode: (json['stockCode'] ?? '').toString(),
      stockName: (json['stockName'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
      riskLevel: (json['riskLevel'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      analysis: _toStringList(json['analysis']),
      checkPoints: _toStringList(json['checkPoints']),
      warnings: _toStringList(json['warnings']),
    );
  }
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}