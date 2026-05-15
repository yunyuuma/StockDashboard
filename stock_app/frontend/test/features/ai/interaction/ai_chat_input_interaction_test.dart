import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/ai/presentation/ai_chat_page.dart';

void main() {
  testWidgets('AIチャットに文字入力できる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiChatPage(),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'トヨタのリスクを教えて',
    );

    await tester.pump();

    expect(find.text('トヨタのリスクを教えて'), findsOneWidget);
  });
}