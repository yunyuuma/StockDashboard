import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/my_page.dart';

void main() {
  testWidgets('マイページの基本表示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyPage(),
      ),
    );

    await tester.pump();

    expect(find.text('マイページ'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}