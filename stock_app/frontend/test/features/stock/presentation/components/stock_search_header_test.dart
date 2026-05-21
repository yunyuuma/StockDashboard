import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/components/stock_search_header.dart';

void main() {
  testWidgets('検索欄に入力できる', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockSearchHeader(controller: controller),
        ),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('コード・企業名・業種・市場で検索'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '7203');
    await tester.pump();

    expect(controller.text, '7203');

    controller.dispose();
  });
}