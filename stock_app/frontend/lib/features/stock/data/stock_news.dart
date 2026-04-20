class StockNews {
  final String title;
  final String link;
  final String publishedAt;
  final String source;

  const StockNews({
    required this.title,
    required this.link,
    required this.publishedAt,
    required this.source,
  });

  factory StockNews.fromJson(Map<String, dynamic> json) {
    return StockNews(
      title: (json['title'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      publishedAt: (json['publishedAt'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
    );
  }

  String get readKey => link.isNotEmpty ? link : '$title|$publishedAt|$source';
}