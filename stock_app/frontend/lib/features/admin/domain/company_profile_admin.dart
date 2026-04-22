class CompanyProfileAdmin {
  final int? id;
  final String stockCode;
  final String companyName;
  final String market;
  final String industry;
  final String website;
  final String description;
  final String mapQuery;
  final String trendsKeyword;
  final bool registered;

  const CompanyProfileAdmin({
    required this.id,
    required this.stockCode,
    required this.companyName,
    required this.market,
    required this.industry,
    required this.website,
    required this.description,
    required this.mapQuery,
    required this.trendsKeyword,
    required this.registered,
  });

  factory CompanyProfileAdmin.fromJson(Map<String, dynamic> json) {
    return CompanyProfileAdmin(
      id: json['id'] as int?,
      stockCode: (json['stockCode'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      industry: (json['industry'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      mapQuery: (json['mapQuery'] ?? '').toString(),
      trendsKeyword: (json['trendsKeyword'] ?? '').toString(),
      registered: (json['registered'] ?? false) as bool,
    );
  }
}