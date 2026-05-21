class AiTradingReview {
  final String summary;
  final int tradeCount;
  final int buyCount;
  final int sellCount;
  final List<String> goodPoints;
  final List<String> weakPoints;
  final List<String> suggestions;
  final List<String> warnings;

  const AiTradingReview({
    required this.summary,
    required this.tradeCount,
    required this.buyCount,
    required this.sellCount,
    required this.goodPoints,
    required this.weakPoints,
    required this.suggestions,
    required this.warnings,
  });

  factory AiTradingReview.fromJson(Map<String, dynamic> json) {
    return AiTradingReview(
      summary: (json['summary'] ?? '').toString(),
      tradeCount: _toInt(json['tradeCount']),
      buyCount: _toInt(json['buyCount']),
      sellCount: _toInt(json['sellCount']),
      goodPoints: _toStringList(json['goodPoints']),
      weakPoints: _toStringList(json['weakPoints']),
      suggestions: _toStringList(json['suggestions']),
      warnings: _toStringList(json['warnings']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}