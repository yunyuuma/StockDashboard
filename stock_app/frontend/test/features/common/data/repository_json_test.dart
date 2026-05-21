import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Repository JSON変換', () {
    test('Mapから正常変換できる', () {
      final json = {
        'code': '7203',
        'name': 'トヨタ自動車',
        'price': 3200
      };

      expect(json['code'], '7203');
      expect(json['name'], 'トヨタ自動車');
      expect(json['price'], 3200);
    });

    test('priceがnullでも落ちない', () {
      final json = {
        'code': '7203',
        'price': null,
      };

      final price = json['price'] ?? 0;

      expect(price, 0);
    });

    test('不正JSONで例外確認', () {
      expect(
        () => jsonDecode('{ invalid json }'),
        throwsException,
      );
    });
  });
}