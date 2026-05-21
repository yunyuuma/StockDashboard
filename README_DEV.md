# StockDashboard Developer README

## 目次

- [システム構成](#システム構成)
- [データベース構成](#データベース構成)
- [ディレクトリ構成](#ディレクトリ構成)
- [API一覧](#api一覧)
- [テスト結果](#テスト結果)
- [テスト確認内容](#テスト確認内容)
- [DB整合性確認](#db整合性確認)
- [起動方法](#起動方法)
- [テスト実行方法](#テスト実行方法)
- [注意点](#注意点)
- [今後の拡張予定](#今後の拡張予定)

---

# システム構成

## Frontend

- Flutter
- Dart
- Provider
- flutter_test
- Widget Test
- Interaction Test

---

## Backend

- Java 17
- Spring Boot 3.5
- Spring Security
- Spring Data JPA
- Hibernate
- MySQL Connector/J
- JUnit5
- Mockito

---

## AI

- Ollama
- qwen2.5:1.5b

---

# データベース構成

本システムでは主に以下の9テーブルを使用しています。

| No | テーブル名 | 内容 |
| --- | --- | --- |
| 1 | users | ユーザ情報、ログイン情報、権限管理 |
| 2 | stocks | 銘柄情報 |
| 3 | company_profiles | 企業情報 |
| 4 | favorites | お気に入り銘柄 |
| 5 | cash_balance | 現金残高 |
| 6 | positions | 保有銘柄 |
| 7 | trades | 約定済み売買履歴 |
| 8 | trade_orders | 注文履歴 |
| 9 | portfolio_snapshots | 資産推移 |

---

# ディレクトリ構成

```text
StockDashboard/
└─ stock_app/
   ├─ backend/
   │  ├─ src/
   │  │  ├─ main/
   │  │  │  ├─ java/
   │  │  │  │  └─ com/example/stockapp/
   │  │  │  │     ├─ controller/
   │  │  │  │     ├─ service/
   │  │  │  │     ├─ repository/
   │  │  │  │     ├─ entity/
   │  │  │  │     ├─ dto/
   │  │  │  │     ├─ security/
   │  │  │  │     ├─ config/
   │  │  │  │     └─ StockAppApplication.java
   │  │  │  └─ resources/
   │  │  │     └─ application.properties
   │  │  └─ test/
   │  ├─ pom.xml
   │  └─ mvnw.cmd
   │
   └─ frontend/
      ├─ lib/
      │  ├─ features/
      │  │  ├─ stock/
      │  │  ├─ portfolio/
      │  │  ├─ ai_chat/
      │  │  ├─ ai_advisor/
      │  │  ├─ trading/
      │  │  └─ my_page/
      │  ├─ models/
      │  ├─ repositories/
      │  ├─ services/
      │  ├─ widgets/
      │  └─ main.dart
      ├─ test/
      │  ├─ features/
      │  ├─ models/
      │  └─ widget_test.dart
      └─ pubspec.yaml
```

---

# API一覧

## 認証系

- POST /auth/login
- POST /auth/register
- GET /users/me
- PUT /users/me
- DELETE /users/{id}

---

## 銘柄系

- GET /stocks
- GET /stocks/{code}
- GET /stocks/history
- GET /stocks/ranking
- GET /stocks/search
- GET /stocks/favorites

---

## お気に入り系

- POST /favorites
- DELETE /favorites
- GET /favorites

---

## 売買系

- POST /trading/order
- DELETE /trading/order
- GET /trading/orders
- GET /trading/history
- GET /trading/portfolio
- POST /trading/buy
- POST /trading/sell

---

## ポートフォリオ系

- GET /portfolio
- GET /portfolio/history
- GET /portfolio/summary

---

## AI系

- POST /ai-advisor/chat
- POST /ai-review
- POST /ai-risk-analysis
- POST /ai-portfolio-analysis

---

## 管理者系

- GET /admin/users
- DELETE /admin/users/{id}
- GET /admin/stocks
- POST /admin/stocks
- PUT /admin/stocks/{id}
- DELETE /admin/stocks/{id}

---

# テスト結果

## Backend

- Tests run: 34
- Failures: 0
- Errors: 0
- BUILD SUCCESS

---

## Frontend

- Tests run: 35
- Failures: 0
- Errors: 0
- All tests passed

---

## 合計

- Total Tests: 69
- Failure: 0
- Error: 0

---

# テスト確認内容

## Backend

- AdminService
- AiAdvisorService
- AiChatService
- AiTradingReviewService
- TradingService
- PortfolioService
- FavoriteService
- Service正常系 / 異常系
- 境界値チェック
- DB更新確認

---

## Frontend

- 銘柄一覧画面表示
- 銘柄検索欄入力
- マイページ表示
- ポートフォリオ画面表示
- AI相談画面
- AIチャットModel変換
- PortfolioSummary JSON変換
- Company.copyWith
- Widget Test
- Interaction Test

---

# DB整合性確認

以下のDB更新を確認済みです。

- BUY後、cash_balance が減少
- BUY後、positions に保有銘柄追加
- SELL後、positions 数量減少
- 全売却時、positions 削除
- trades に BUY / SELL 履歴保存
- trade_orders に OPEN / FILLED / CANCELED 保存
- favorites の登録 / 解除反映

---

# 起動方法

## Backend

```bash
cd stock_app/backend
./mvnw spring-boot:run
```

Windows の場合:

```bash
cd stock_app/backend
mvnw.cmd spring-boot:run
```

---

## Frontend

```bash
cd stock_app/frontend
flutter pub get
flutter run
```

---

# テスト実行方法

## Backend

```bash
cd stock_app/backend
mvnw.cmd test
```

## Frontend

```bash
cd stock_app/frontend
flutter test
```

---

# 注意点

- Backend起動前に MySQL を起動しておく必要があります。
- Ollama を使用するAI機能は、Ollama未起動時にエラー表示されます。
- StockDetailPage はHTTP通信依存が強いため、一部手動確認対象です。
- API通信を行う画面では、Backend が起動していない場合、データ取得エラーになります。

---

# 今後の拡張予定

- 実際の証券API連携
- リアルタイム株価配信
- AI銘柄ランキング
- ニュース分析
- テクニカル分析
- WebSocket対応
- Push通知
- ダークモード対応