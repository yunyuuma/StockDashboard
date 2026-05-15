import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ai/domain/ai_advisor_models.dart';

void main() {
  group('AiAdvisorResult', () {
    test('JSONから変換できる', () {
      final result = AiAdvisorResult.fromJson({
        'summary': 'リスクは標準です。',
        'riskLevel': 'MIDDLE',
        'portfolioAdvice': ['分散を意識しましょう'],
        'tradingAdvice': ['売買履歴を確認しましょう'],
        'warnings': ['これは投資助言ではありません'],
      });

      expect(result.summary, 'リスクは標準です。');
      expect(result.riskLevel, 'MIDDLE');
      expect(result.portfolioAdvice.length, 1);
      expect(result.tradingAdvice.length, 1);
      expect(result.warnings.length, 1);
    });
  });
}