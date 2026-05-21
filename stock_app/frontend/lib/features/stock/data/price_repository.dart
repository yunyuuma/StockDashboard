import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class PriceRepository {
  PriceRepository({
    required String proxyBaseUrl,
    http.Client? client,
  })  : proxyBaseUrl = _normalizeBaseUrl(proxyBaseUrl),
        _client = client ?? http.Client();

  final String proxyBaseUrl;
  final http.Client _client;

  Future<Map<String, Quote>> fetchAllQuotes() async {
    final baseUri = Uri.parse(proxyBaseUrl);
    final uri = baseUri.replace(path: '/quotes');

    final res = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json,text/plain,*/*',
      },
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception(
        'price snapshot status=${res.statusCode} url=$uri body=${_shrink(res.body)}',
      );
    }

    final body = res.body.trimLeft();
    if (!body.startsWith('{')) {
      throw Exception('price snapshot returned non-json: ${_shrink(res.body)}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('price snapshot invalid json: ${_shrink(res.body)}');
    }

    final source = _extractQuoteSource(decoded);
    return _parseQuoteMap(source);
  }

  Future<Map<String, Quote>> refreshQuotes(
    List<String> codes, {
    int batchSize = 15,
    Duration delayBetweenBatches = const Duration(milliseconds: 250),
    void Function(int done, int total)? onProgress,
  }) async {
    final normalized =
        codes.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    final total = normalized.length;
    final out = <String, Quote>{};

    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize < total) ? i + batchSize : total;
      final batch = normalized.sublist(i, end);

      final got = await _refreshBatch(batch);
      out.addAll(got);

      onProgress?.call(end, total);

      if (end < total) {
        await Future<void>.delayed(delayBetweenBatches);
      }
    }

    return out;
  }

  Future<Map<String, Quote>> _refreshBatch(List<String> codes) async {
    if (codes.isEmpty) return {};

    final baseUri = Uri.parse(proxyBaseUrl);
    final uri = baseUri.replace(
      path: '/quotes',
      queryParameters: {
        'codes': codes.join(','),
      },
    );

    final res = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json,text/plain,*/*',
      },
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception(
        'price refresh status=${res.statusCode} url=$uri body=${_shrink(res.body)}',
      );
    }

    final body = res.body.trimLeft();
    if (!body.startsWith('{')) {
      throw Exception('price refresh returned non-json: ${_shrink(res.body)}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('price refresh invalid json: ${_shrink(res.body)}');
    }

    final source = _extractQuoteSource(decoded);
    return _parseQuoteMap(source);
  }

  Map<String, dynamic> _extractQuoteSource(Map<String, dynamic> decoded) {
    final maybeSnapshot = decoded['snapshot'];
    if (maybeSnapshot is Map<String, dynamic>) {
      return maybeSnapshot;
    }

    final maybeData = decoded['data'];
    if (maybeData is Map<String, dynamic>) {
      return maybeData;
    }

    return decoded;
  }

  Map<String, Quote> _parseQuoteMap(Map<String, dynamic> source) {
    final out = <String, Quote>{};

    for (final entry in source.entries) {
      final code = entry.key.trim();
      final value = entry.value;

      if (value is! Map) continue;

      final ok = value['ok'] == true;
      if (!ok) continue;

      final price = _num(value['price']);
      final changePct = _num(value['changePct']);

      if (price <= 0) continue;

      out[code] = Quote(
        price: price,
        changePct: changePct,
      );
    }

    return out;
  }

  static String _normalizeBaseUrl(String s) {
    var v = s.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String _shrink(String s, {int max = 220}) =>
      s.length <= max ? s : '${s.substring(0, max)}...';

  void dispose() => _client.close();
}

class Quote {
  final double price;
  final double changePct;

  const Quote({
    required this.price,
    required this.changePct,
  });
}