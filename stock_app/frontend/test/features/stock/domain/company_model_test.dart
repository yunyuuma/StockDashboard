import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/stock/domain/company.dart';

void main() {
  group('Company', () {
    test('copyWithでお気に入り状態を変更できる', () {
      final company = Company(
        code: '7203',
        name: 'トヨタ自動車',
        kana: 'トヨタジドウシャ',
        market: 'プライム',
        industry: '輸送用機器',
        price: 3200,
        changePct: 1.25,
        marketCap: 100000000,
        volume: 1000000,
        favorite: false,
      );

      final updated = company.copyWith(favorite: true);

      expect(updated.code, '7203');
      expect(updated.favorite, true);
      expect(company.favorite, false);
    });
  });
}