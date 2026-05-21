import 'package:flutter_test/flutter_test.dart';

import 'package:stock_app/features/trading/domain/portfolio_models.dart';

void main() {
  group('PortfolioSummary', () {
    test('JSONからポートフォリオ情報を変換できる', () {
      final summary = PortfolioSummary.fromJson({
        'cash': 500000,
        'stockValue': 320000,
        'totalAsset': 820000,
        'profitLoss': -180000,
        'profitLossRate': -18.0,
        'dailyProfitLoss': 10000,
        'dailyProfitLossRate': 1.2,
        'maxDrawdown': 30000,
        'maxDrawdownRate': 3.0,
        'points': [
          {
            'dateTime': '2026-05-01T10:00:00',
            'cash': 1000000,
            'stockValue': 0,
            'totalAsset': 1000000,
            'eventLabel': '開始',
          },
          {
            'dateTime': '2026-05-02T10:00:00',
            'cash': 500000,
            'stockValue': 320000,
            'totalAsset': 820000,
            'eventLabel': '7203 買い',
          },
        ],
        'sectorAllocations': [
          {
            'sector': '輸送用機器',
            'amount': 320000,
            'rate': 100,
          },
        ],
      });

      expect(summary.cash, 500000);
      expect(summary.stockValue, 320000);
      expect(summary.totalAsset, 820000);
      expect(summary.profitLoss, -180000);
      expect(summary.points.length, 2);
      expect(summary.points[0].marketValue, 0);
      expect(summary.sectorAllocations.length, 1);
      expect(summary.sectorAllocations[0].sector, '輸送用機器');
    });

    test('数値が文字列でもdoubleに変換できる', () {
      final summary = PortfolioSummary.fromJson({
        'cash': '500000',
        'stockValue': '320000',
        'totalAsset': '820000',
        'profitLoss': '-180000',
        'profitLossRate': '-18.0',
        'dailyProfitLoss': '10000',
        'dailyProfitLossRate': '1.2',
        'maxDrawdown': '30000',
        'maxDrawdownRate': '3.0',
        'points': [],
        'sectorAllocations': [],
      });

      expect(summary.cash, 500000);
      expect(summary.profitLossRate, -18.0);
      expect(summary.points, isEmpty);
      expect(summary.sectorAllocations, isEmpty);
    });
  });
}