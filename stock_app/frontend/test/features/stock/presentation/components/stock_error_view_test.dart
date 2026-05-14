import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/stock/presentation/components/stock_error_view.dart';

void main() {
  testWidgets('エラー表示と再試行ボタンが動く', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockErrorView(
            title: 'データ取得に失敗しました',
            message: '通信エラー',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('データ取得に失敗しました'), findsOneWidget);
    expect(find.text('通信エラー'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pump();

    expect(retried, true);
  });
}