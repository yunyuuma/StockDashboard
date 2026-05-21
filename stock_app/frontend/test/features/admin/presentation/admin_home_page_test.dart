import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/admin/presentation/admin_home_page.dart';

void main() {
  testWidgets('管理者ホーム画面の基本表示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomePage(),
      ),
    );

    await tester.pump();

    expect(find.textContaining('管理'), findsWidgets);
  });
}