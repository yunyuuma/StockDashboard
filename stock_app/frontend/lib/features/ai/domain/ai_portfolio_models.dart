class AiPortfolioAdvisor {
  final String riskLevel;
  final String summary;
  final List<String> strengths;
  final List<String> risks;
  final List<String> suggestions;

  const AiPortfolioAdvisor({
    required this.riskLevel,
    required this.summary,
    required this.strengths,
    required this.risks,
    required this.suggestions,
  });

  factory AiPortfolioAdvisor.fromJson(Map<String, dynamic> json) {
    return AiPortfolioAdvisor(
      riskLevel: (json['riskLevel'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      strengths: _list(json['strengths']),
      risks: _list(json['risks']),
      suggestions: _list(json['suggestions']),
    );
  }

  static List<String> _list(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).toList();
  }
}