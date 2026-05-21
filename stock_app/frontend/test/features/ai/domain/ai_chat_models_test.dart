import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/ai/domain/ai_chat_models.dart';

void main() {
  group('AiChatResponse', () {
    test('answerをJSONから変換できる', () {
      final response = AiChatResponse.fromJson({
        'answer': 'これは学習用コメントです。',
      });

      expect(response.answer, 'これは学習用コメントです。');
    });

    test('answerがnullなら空文字になる', () {
      final response = AiChatResponse.fromJson({
        'answer': null,
      });

      expect(response.answer, '');
    });
  });

  group('AiChatMessage', () {
    test('ユーザメッセージを作成できる', () {
      const message = AiChatMessage(
        text: 'トヨタについて教えて',
        fromUser: true,
      );

      expect(message.text, 'トヨタについて教えて');
      expect(message.fromUser, true);
    });
  });
}