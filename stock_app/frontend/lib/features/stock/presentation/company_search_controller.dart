import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/company_repository.dart';
import '../data/price_repository.dart';
import '../domain/company.dart';

enum FilterTab { industry, price }
enum SortField { none, ticker, price, change }
enum SortDir { none, asc, desc }

final companySearchControllerProvider =
    ChangeNotifierProvider<CompanySearchController>((ref) {
  return CompanySearchController();
});

class CompanySearchController extends ChangeNotifier {
  final CompanyRepository _repo = CompanyRepository();

  final PriceRepository priceRepo =
      PriceRepository(proxyBaseUrl: 'https://workers.gikiin67.workers.dev');

  /// 初回ロード済み判定
  bool _initialized = false;

  /// 全銘柄
  List<Company> _all = [];

  /// 表示結果（お気に入り株価一覧用）
  List<Company> _result = [];
  List<Company> get result => _result;

  /// お気に入り銘柄の株価キャッシュ
  final Map<String, Quote> _quotesCache = {};

  /// UI状態
  FilterTab tab = FilterTab.industry;

  String _query = '';
  String get query => _query;

  String? _industry;
  String? get industryFilter => _industry;

  double _priceMin = 0;
  double _priceMax = 10000;
  double get priceMin => _priceMin;
  double get priceMax => _priceMax;

  double _priceRangeMin = 0;
  double _priceRangeMax = 10000;
  double get priceRangeMin => _priceRangeMin;
  double get priceRangeMax => _priceRangeMax;

  SortField _sortField = SortField.none;
  SortDir _sortDir = SortDir.none;
  SortField get sortField => _sortField;
  SortDir get sortDir => _sortDir;

  Timer? _debounce;

  bool _loading = false;
  bool get loading => _loading;

  int _done = 0;
  int get done => _done;

  int _total = 0;
  int get total => _total;

  String? _lastError;
  String? get lastError => _lastError;

  /// 初期ロード：初回だけ企業一覧を取得
  Future<void> load() async {
    if (_initialized) return;

    _loading = true;
    _lastError = null;
    _done = 0;
    notifyListeners();

    try {
      final list = await _repo.fetchAll();
      _all = list;
      _total = list.length;

      _initialized = true;

      _apply();
    } catch (e) {
      _lastError = e.toString();
      print('load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// お気に入り銘柄だけ株価/前日比を更新
  Future<void> refreshFavoriteQuotes() async {
    _loading = true;
    _lastError = null;
    _done = 0;
    notifyListeners();

    try {
      final favoriteCodes = _all
          .where((c) => c.favorite)
          .map((c) => c.code.trim())
          .where((code) => code.isNotEmpty)
          .toList();

      _total = favoriteCodes.length;

      if (favoriteCodes.isEmpty) {
        _applyQuotesToFavoritesOnly();
        _apply();
        return;
      }

      // ① snapshot から全件読む
      try {
        final snapshotQuotes = await priceRepo.fetchAllQuotes();

        for (final code in favoriteCodes) {
          final q = snapshotQuotes[code];
          if (q != null) {
            _quotesCache[code] = q;
          }
        }
      } catch (e) {
        print('snapshot fetch error: $e');
      }

      // ② 未取得のお気に入りだけ更新
      final missingCodes =
          favoriteCodes.where((code) => !_quotesCache.containsKey(code)).toList();

      if (missingCodes.isNotEmpty) {
        final refreshed = await priceRepo.refreshQuotes(
          missingCodes,
          batchSize: 15,
          delayBetweenBatches: const Duration(milliseconds: 250),
          onProgress: (doneFetched, totalFetched) {
            _done = (_quotesCache.length + doneFetched).clamp(0, _total);
            notifyListeners();
          },
        );

        _quotesCache.addAll(refreshed);
      }

      _applyQuotesToFavoritesOnly();
      _done = favoriteCodes.where((c) => _quotesCache.containsKey(c)).length;
      _recalculatePriceRangeFromFavorites();
      _apply();
    } catch (e) {
      _lastError = e.toString();
      print('refreshFavoriteQuotes error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// お気に入り登録画面用一覧
  List<Company> get registerList {
    final q = _normalize(_query);

    var list = _all.where((c) {
      if (q.isEmpty) return true;

      final idx = _normalize(
        '${c.code} ${c.name} ${c.kana} ${c.market} ${c.industry}',
      );
      return idx.contains(q);
    }).toList();

    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  /// お気に入りだけ株価を反映し、それ以外は0に戻す
  void _applyQuotesToFavoritesOnly() {
    _all = _all.map((c) {
      if (!c.favorite) {
        return c.copyWith(
          price: 0,
          changePct: 0,
        );
      }

      final q = _quotesCache[c.code.trim()];
      if (q == null) {
        return c.copyWith(
          price: 0,
          changePct: 0,
        );
      }

      return c.copyWith(
        price: q.price,
        changePct: q.changePct,
      );
    }).toList();
  }

  /// お気に入り銘柄の株価レンジを再計算
  void _recalculatePriceRangeFromFavorites() {
    final favoritePrices = _all
        .where((c) => c.favorite && c.price > 0)
        .map((c) => c.price)
        .toList();

    if (favoritePrices.isEmpty) {
      _priceRangeMin = 0;
      _priceRangeMax = 10000;
      _priceMin = 0;
      _priceMax = 10000;
      return;
    }

    favoritePrices.sort();
    _priceRangeMin = favoritePrices.first.floorToDouble();
    _priceRangeMax = favoritePrices.last.ceilToDouble();

    if (_priceRangeMin == _priceRangeMax) {
      _priceRangeMax = _priceRangeMin + 1;
    }

    _priceMin = _priceRangeMin;
    _priceMax = _priceRangeMax;
  }

  void clearQuoteCache() {
    _quotesCache.clear();
    _done = 0;
    notifyListeners();
  }

  /// 必要ならロード状態をリセット
  void resetLoadState() {
    _initialized = false;
  }

  /// 検索
  void setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = q.trim();
      _apply();
    });
  }

  /// タブ切替
  void setTab(FilterTab t) {
    tab = t;
    _apply();
  }

  /// 業種フィルタ
  void setIndustry(String industry) {
    _industry = industry;
    tab = FilterTab.industry;
    _apply();
  }

  void clearIndustry() {
    _industry = null;
    _apply();
  }

  /// 株価スライダー範囲
  void setPriceSliderRange(double min, double max) {
    _priceMin = min;
    _priceMax = max;
    tab = FilterTab.price;
    _apply();
  }

  void resetPriceRange() {
    _priceMin = _priceRangeMin;
    _priceMax = _priceRangeMax;
    _apply();
  }

  /// お気に入り切替
  void toggleFavorite(Company c) {
    bool addedToFavorite = false;

    _all = _all.map((x) {
      if (x.code != c.code) return x;

      final newFavorite = !x.favorite;
      if (newFavorite) addedToFavorite = true;

      if (!newFavorite) {
        _quotesCache.remove(x.code.trim());
      }

      return x.copyWith(
        favorite: newFavorite,
        price: newFavorite ? x.price : 0,
        changePct: newFavorite ? x.changePct : 0,
      );
    }).toList();

    _apply();

    if (addedToFavorite) {
      refreshFavoriteQuotes();
    } else {
      _recalculatePriceRangeFromFavorites();
      _apply();
    }
  }

  /// 業種一覧（お気に入りのみ）
  List<String> get industries {
    final set = <String>{};

    for (final c in _all.where((e) => e.favorite)) {
      final v = c.industry.trim();
      if (v.isNotEmpty) set.add(v);
    }

    final list = set.toList()..sort();
    return list;
  }

  /// ソート
  void toggleSortTicker() => _toggleSort(SortField.ticker);
  void toggleSortPrice() => _toggleSort(SortField.price);
  void toggleSortChange() => _toggleSort(SortField.change);

  void _toggleSort(SortField field) {
    if (_sortField != field) {
      _sortField = field;
      _sortDir = SortDir.asc;
    } else {
      if (_sortDir == SortDir.asc) {
        _sortDir = SortDir.desc;
      } else if (_sortDir == SortDir.desc) {
        _sortField = SortField.none;
        _sortDir = SortDir.none;
      } else {
        _sortDir = SortDir.asc;
      }
    }
    _apply();
  }

  /// フィルタ + ソート
  void _apply() {
    final q = _normalize(_query);

    // お気に入り以外は表示しない
    var list = _all.where((c) {
      if (!c.favorite) return false;

      if (q.isNotEmpty) {
        final idx = _normalize(
          '${c.code} ${c.name} ${c.kana} ${c.market} ${c.industry}',
        );
        if (!idx.contains(q)) return false;
      }

      if (_industry != null && _industry!.isNotEmpty) {
        if (c.industry != _industry) return false;
      }

      if (c.price < _priceMin) return false;
      if (c.price > _priceMax) return false;

      return true;
    }).toList();

    if (_sortField != SortField.none && _sortDir != SortDir.none) {
      int cmp(Company a, Company b) {
        switch (_sortField) {
          case SortField.ticker:
            return a.code.compareTo(b.code);
          case SortField.price:
            return a.price.compareTo(b.price);
          case SortField.change:
            return a.changePct.compareTo(b.changePct);
          case SortField.none:
            return 0;
        }
      }

      list.sort((a, b) => _sortDir == SortDir.asc ? cmp(a, b) : cmp(b, a));
    }

    _result = list;
    notifyListeners();
  }

  static String _normalize(String s) => s.toLowerCase();

  @override
  void dispose() {
    _debounce?.cancel();
    priceRepo.dispose();
    super.dispose();
  }
}