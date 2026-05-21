import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/domain/company.dart';
import 'package:stock_app/features/stock/presentation/components/stock_list_card.dart';

void main() {
  testWidgets('銘柄カードとお気に入りボタンを押下できる', (tester) async {
    var cardTapped = false;
    var favoriteTapped = false;

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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockListCard(
            company: company,
            onTap: () => cardTapped = true,
            onFavoriteTap: () => favoriteTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('トヨタ自動車'));
    await tester.pump();
    expect(cardTapped, true);

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(favoriteTapped, true);
  });
}