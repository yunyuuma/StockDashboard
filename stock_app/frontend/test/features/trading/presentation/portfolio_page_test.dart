import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/trading/presentation/portfolio_page.dart';

void main() {
  testWidgets('ポートフォリオ画面の基本表示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortfolioPage(),
      ),
    );

    await tester.pump();

    expect(find.text('ポートフォリオ'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}