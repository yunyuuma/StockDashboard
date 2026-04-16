import 'package:flutter/material.dart';

class NewsItem {
  final String id;
  final String title;
  final String source;
  final DateTime date;

  const NewsItem({
    required this.id,
    required this.title,
    required this.source,
    required this.date,
  });
}

class NewsSection extends StatefulWidget {
  final String ticker;

  const NewsSection({
    super.key,
    required this.ticker,
  });

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  /// ダミーニュース
  final List<NewsItem> _allNews = [
    NewsItem(
      id: "1",
      title: "トヨタ、EV投資を拡大",
      source: "日経",
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NewsItem(
      id: "2",
      title: "半導体需要回復で株価上昇",
      source: "Bloomberg",
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NewsItem(
      id: "3",
      title: "アナリストが目標株価を引き上げ",
      source: "Reuters",
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NewsItem(
      id: "4",
      title: "新製品発表で市場期待",
      source: "Yahoo Finance",
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// 閲覧履歴
  final Set<String> _viewed = {};

  List<NewsItem> get _sortedNews {
    final unseen = _allNews.where((n) => !_viewed.contains(n.id)).toList();
    final seen = _allNews.where((n) => _viewed.contains(n.id)).toList();

    return [...unseen, ...seen];
  }

  void _openNews(NewsItem news) {
    setState(() {
      _viewed.add(news.id);
    });

    /// 仮ニュース詳細
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(news.title),
        content: const Text("ニュース本文（仮）"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsList = _sortedNews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "関連ニュース",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(newsList.length, (index) {
          final news = newsList[index];
          final viewed = _viewed.contains(news.id);

          /// フェード計算
          final fade = viewed ? (1 - (index / newsList.length)) * 0.5 : 1.0;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: fade.clamp(0.3, 1),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NewsCard(
                news: news,
                viewed: viewed,
                onTap: () => _openNews(news),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem news;
  final bool viewed;
  final VoidCallback onTap;

  const _NewsCard({
    required this.news,
    required this.viewed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: viewed
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    news.source,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(news.date),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (viewed)
                    const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey,
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}分前";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours}時間前";
    }

    return "${diff.inDays}日前";
  }
}