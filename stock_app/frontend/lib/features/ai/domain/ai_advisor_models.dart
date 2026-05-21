class AiAdvisorResult {
  final String riskLevel;
  final String summary;
  final List<String> portfolioAdvice;
  final List<String> tradingAdvice;
  final List<String> warnings;

  const AiAdvisorResult({
    required this.riskLevel,
    required this.summary,
    required this.portfolioAdvice,
    required this.tradingAdvice,
    required this.warnings,
  });

  factory AiAdvisorResult.fromJson(Map<String, dynamic> json) {
    return AiAdvisorResult(
      riskLevel: (json['riskLevel'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      portfolioAdvice: _toStringList(json['portfolioAdvice']),
      tradingAdvice: _toStringList(json['tradingAdvice']),
      warnings: _toStringList(json['warnings']),
    );
  }
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}