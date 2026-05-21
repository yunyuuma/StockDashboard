import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/domain/company.dart';
import 'package:stock_app/features/stock/presentation/components/stock_list_card.dart';

void main() {
  group('StockListCard', () {
    testWidgets('銘柄名・コード・市場・業種が表示される', (tester) async {
      final company = Company(
        code: '7203',
        name: 'トヨタ自動車',
        kana: 'トヨタジドウシャ',
        market: 'プライム',
        industry: '輸送用機器',
        price: 3200,
        changePct: 1.25,
        marketCap: 100000000,
        volume: 123456,
        favorite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockListCard(
              company: company,
              onTap: () {},
              onFavoriteTap: () {},
              favoriteTooltip: 'お気に入り登録',
            ),
          ),
        ),
      );

      expect(find.text('トヨタ自動車'), findsOneWidget);
      expect(find.text('7203'), findsOneWidget);
      expect(find.text('プライム'), findsOneWidget);
      expect(find.text('輸送用機器'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('お気に入り済みなら黄色スターが表示される', (tester) async {
      final company = Company(
        code: '6758',
        name: 'ソニーグループ',
        kana: 'ソニーグループ',
        market: 'プライム',
        industry: '電気機器',
        price: 15000,
        changePct: -0.8,
        marketCap: 100000000,
        volume: 123456,
        favorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockListCard(
              company: company,
              onTap: () {},
              onFavoriteTap: () {},
              favoriteTooltip: 'お気に入り解除',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('カード押下とお気に入り押下が反応する', (tester) async {
      var tapped = false;
      var favoriteTapped = false;

      final company = Company(
        code: '9984',
        name: 'ソフトバンクグループ',
        kana: 'ソフトバンクグループ',
        market: 'プライム',
        industry: '情報・通信業',
        price: 9000,
        changePct: 0.5,
        marketCap: 100000000,
        volume: 123456,
        favorite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockListCard(
              company: company,
              onTap: () {
                tapped = true;
              },
              onFavoriteTap: () {
                favoriteTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('ソフトバンクグループ'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      expect(tapped, true);
      expect(favoriteTapped, true);
    });
  });
}