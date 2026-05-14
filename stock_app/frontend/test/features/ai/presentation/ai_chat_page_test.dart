import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/ai/presentation/ai_chat_page.dart';

void main() {
  testWidgets('AIチャット初期表示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiChatPage(),
      ),
    );

    expect(find.text('AIチャット'), findsOneWidget);
    expect(find.textContaining('株価・保有銘柄・疑似売買'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('銘柄コード付きAIチャット初期表示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiChatPage(stockCode: '7203'),
      ),
    );

    expect(find.text('AIチャット 7203'), findsOneWidget);
    expect(find.textContaining('銘柄コード 7203'), findsWidgets);
    expect(find.text('例：この銘柄の注意点を教えて'), findsOneWidget);
  });
}