class StockDetailSummary {
  final String code;
  final String name;
  final String market;
  final String industry;
  final double price;
  final double changePct;
  final double high;
  final double low;
  final double open;
  final double close;
  final double volume;

  const StockDetailSummary({
    required this.code,
    required this.name,
    required this.market,
    required this.industry,
    required this.price,
    required this.changePct,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
  });
}

class StockChartPoint {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const StockChartPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockNewsItem {
  final String title;
  final String source;
  final String publishedAt;
  final String url;

  const StockNewsItem({
    required this.title,
    required this.source,
    required this.publishedAt,
    required this.url,
  });
}

class StockMetrics {
  final double per;
  final double pbr;
  final double roe;
  final double dividendYield;
  final double marketCap;

  const StockMetrics({
    required this.per,
    required this.pbr,
    required this.roe,
    required this.dividendYield,
    required this.marketCap,
  });
}

class StockCompanyInfo {
  final String companyName;
  final String market;
  final String industry;
  final String description;
  final String website;
  final String headquarters;

  const StockCompanyInfo({
    required this.companyName,
    required this.market,
    required this.industry,
    required this.description,
    required this.website,
    required this.headquarters,
  });
}