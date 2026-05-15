import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/components/stock_search_header.dart';

void main() {
  testWidgets('検索欄に銘柄コードを入力できる', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockSearchHeader(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '7203');
    await tester.pump();

    expect(controller.text, '7203');

    controller.dispose();
  });
}