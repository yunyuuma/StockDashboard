# StockDashboard

## 概要

StockDashboard は、Flutter + Spring Boot + MySQL + Ollama を利用した総合株価ダッシュボードアプリです。

本アプリは単なる株価閲覧アプリではなく、

- 株価確認
- 銘柄分析
- お気に入り管理
- 疑似売買
- 保有資産管理
- ポートフォリオ分析
- AI投資相談
- AI売買レビュー

までを一括管理できる投資支援アプリとして構成されています。

---

# システム構成

## Frontend

Flutter ベースで構築されています。

### 主な画面

- ログイン画面
- 新規登録画面
- 銘柄一覧画面
- 銘柄詳細画面
- お気に入り画面
- ポートフォリオ画面
- AI相談画面
- 疑似売買画面
- 管理者画面
- マイページ

### 使用技術

- Flutter
- Dart
- Provider
- flutter_test
- Widget Test
- Interaction Test

---

## Backend

Spring Boot ベースで REST API を提供しています。

### 主な機能

- JWT認証
- ユーザ管理
- 銘柄情報管理
- お気に入り管理
- 疑似売買処理
- ポートフォリオ集計
- AIレビュー生成
- AIチャット
- 管理者機能

### 使用技術

- Java 17
- Spring Boot 3.5
- Spring Security
- Spring Data JPA
- Hibernate
- MySQL Connector/J
- JUnit5
- Mockito

---

# AI機能

AIには Ollama を利用しています。

## 使用モデル

- qwen2.5:1.5b

## AI機能一覧

- 投資相談
- 売買レビュー
- リスク分析
- ポートフォリオ分析
- 売買履歴分析
- 集中投資リスク判定
- 含み損分析
- AIチャット

---

# 主な機能

## 認証機能

- ログイン
- 新規登録
- JWT認証
- ユーザ情報取得
- 管理者 / 一般ユーザ権限制御

---

## 銘柄機能

- 銘柄一覧表示
- 銘柄検索
- 銘柄詳細表示
- 株価チャート表示
- 企業情報表示
- お気に入り登録 / 解除

---

## 疑似売買機能

- 成行買い
- 成行売り
- 指値注文
- 注文取消
- 注文履歴管理
- 約定履歴管理
- 現金残高更新
- 保有銘柄更新

---

## ポートフォリオ機能

- 総資産表示
- 現金残高表示
- 保有銘柄一覧
- 評価額計算
- 損益計算
- 日次損益
- 最大ドローダウン
- 資産推移表示

---

## AI機能

- AIチャット
- AI投資相談
- 保有銘柄に基づくアドバイス
- 売買履歴レビュー
- リスク分析
- 集中投資への警告
- 含み損分析
- Ollama停止時エラー表示

---

## 管理者機能

- ユーザ管理
- ユーザ削除
- 関連お気に入り削除
- 銘柄管理
- 企業情報更新
- 管理者系Serviceテスト

---

# データベース構成

本システムでは主に以下の9テーブルを使用しています。

| No | テーブル名 | 内容 |
| --- | --- | --- |
| 1 | users | ユーザ情報、ログイン情報、権限管理 |
| 2 | stocks / companies | 銘柄情報、企業情報 |
| 3 | stock_price_histories | 株価履歴、チャート表示用データ |
| 4 | favorites | お気に入り銘柄 |
| 5 | cash_balance | 現金残高 |
| 6 | positions | 保有銘柄 |
| 7 | trades | 約定済み売買履歴 |
| 8 | trade_orders | 注文履歴 |
| 9 | ai_chat_histories / portfolio_histories | AI履歴または資産推移 |

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
- 疑似売買は実際の証券会社注文ではなく、アプリ内の紙トレード機能です。
- API通信を行う画面では、Backend が起動していない場合、データ取得エラーになります。
- MySQL の接続情報は `application.properties` に設定されています。

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
- 管理者画面の機能拡張
- ポートフォリオ推移グラフの強化

---

# まとめ

StockDashboard は、株価確認だけではなく、

- 銘柄検索
- お気に入り管理
- 疑似売買
- 保有資産管理
- ポートフォリオ分析
- AI投資相談
- AI売買レビュー

までを一体化した投資支援型株価ダッシュボードアプリです。

Frontend は Flutter、Backend は Spring Boot、Database は MySQL、AI は Ollama を利用しています。

Backend / Frontend ともにテストが通過しており、合計69件のテストで Failure / Error 0 を確認しています。