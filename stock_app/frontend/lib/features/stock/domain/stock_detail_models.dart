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
  final String disclosedDate;
  final String disclosedTime;
  final String typeOfDocument;
  final String currentPeriodEndDate;

  final double netSales;
  final double operatingProfit;
  final double ordinaryProfit;
  final double profit;
  final double earningsPerShare;

  final double forecastNetSales;
  final double forecastOperatingProfit;
  final double forecastOrdinaryProfit;
  final double forecastProfit;

  final double annualDividendPerShareForecast;

  const StockMetrics({
    required this.disclosedDate,
    required this.disclosedTime,
    required this.typeOfDocument,
    required this.currentPeriodEndDate,
    required this.netSales,
    required this.operatingProfit,
    required this.ordinaryProfit,
    required this.profit,
    required this.earningsPerShare,
    required this.forecastNetSales,
    required this.forecastOperatingProfit,
    required this.forecastOrdinaryProfit,
    required this.forecastProfit,
    required this.annualDividendPerShareForecast,
  });
}

class StockCompanyInfo {
  final String companyName;
  final String market;
  final String industry;
  final String description;
  final String website;
  final String mapQuery;
  final String trendsKeyword;

  const StockCompanyInfo({
    required this.companyName,
    required this.market,
    required this.industry,
    required this.description,
    required this.website,
    required this.mapQuery,
    required this.trendsKeyword,
  });
}