import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/components/stock_market_chip_row.dart';

void main() {
  testWidgets('市場チップを押下できる', (tester) async {
    String? selectedMarket;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockMarketChipRow(
            markets: const ['プライム', 'スタンダード', 'グロース'],
            selectedMarket: null,
            onSelected: (value) {
              selectedMarket = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('プライム'));
    await tester.pump();

    expect(selectedMarket, 'プライム');
  });
}