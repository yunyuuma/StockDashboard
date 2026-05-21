import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/company_search_page.dart';

void main() {

  group('CompanySearchPage', () {

    testWidgets('銘柄一覧画面が表示される', (tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: CompanySearchPage(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);

      expect(find.byIcon(Icons.search), findsWidgets);

      expect(find.byIcon(Icons.refresh), findsWidgets);

    });

    testWidgets('検索欄に入力できる', (tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: CompanySearchPage(),
        ),
      );

      final textField =
          find.byType(TextField).first;

      await tester.enterText(
        textField,
        '7203',
      );

      await tester.pump();

      expect(find.text('7203'), findsWidgets);

    });

  });

}