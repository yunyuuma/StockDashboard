import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/components/stock_market_chip_row.dart';

void main() {
  testWidgets('市場チップを選択できる', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockMarketChipRow(
            markets: const ['プライム', 'スタンダード', 'グロース'],
            selectedMarket: null,
            onSelected: (value) {
              selected = value;
            },
          ),
        ),
      ),
    );

    expect(find.text('すべて'), findsOneWidget);
    expect(find.text('プライム'), findsOneWidget);
    expect(find.text('スタンダード'), findsOneWidget);
    expect(find.text('グロース'), findsOneWidget);

    await tester.tap(find.text('プライム'));
    await tester.pump();

    expect(selected, 'プライム');
  });
}