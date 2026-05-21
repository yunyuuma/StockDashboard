# StockDashboard

## 目次

- [概要](#概要)
- [システム構成](#システム構成)
- [AI機能](#ai機能)
- [主な機能](#主な機能)
- [起動方法](#起動方法)
- [注意点](#注意点)
- [今後の拡張予定](#今後の拡張予定)
- [開発者向けREADME](#開発者向けreadme)
- [まとめ](#まとめ)

---

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

---

## Backend

Spring Boot ベースで REST API を提供しています。

### 使用技術

- Java 17
- Spring Boot 3.5
- Spring Security
- Spring Data JPA
- Hibernate
- MySQL Connector/J

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
- AIチャット

---

# 主な機能

## 認証機能

- ログイン
- 新規登録
- JWT認証（二段階認証）
- 管理者 / 一般ユーザ権限制御

---

## 銘柄機能

- 銘柄一覧表示
- 銘柄検索
- 銘柄詳細表示
- 株価チャート表示
- お気に入り登録 / 解除

---

## 疑似売買機能

- 成行買い
- 成行売り
- 指値注文
- 逆指値注文
- IFD注文
- OCO注文
- IFDOCO注文

---

## ポートフォリオ機能

- 総資産表示
- 現金残高表示
- 保有銘柄一覧
- 損益計算
- 資産推移表示

---

## AI機能

- AIチャット
- AI投資相談
- 売買履歴レビュー
- リスク分析
- 含み損分析

---

## 管理者機能

- ユーザ管理
- 銘柄管理
- 企業情報更新

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

# 注意点

- Backend起動前に MySQL を起動しておく必要があります。
- Ollama を使用するAI機能は、Ollama未起動時にエラー表示されます。
- 疑似売買は実際の証券会社注文ではなく、アプリ内の紙トレード機能です。

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

---

# 開発者向けREADME

詳細な設計・API・DB・テスト内容については README_DEV.md を参照してください。

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