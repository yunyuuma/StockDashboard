# StockDashboard

## 概要

DB、APIの移行、CloudFlareよりFlutter側のデプロイ

---

# システム構成

```text
[Flutter Web]
        ↓
Cloudflare Pages

        ↓ API

[Spring Boot]
        ↓
Render

        ↓

[Supabase PostgreSQL]
```

---

# 使用技術

## Frontend

- Flutter Web
- Dart

## Backend

- Spring Boot 3.5
- Spring Security
- Spring Data JPA
- JWT認証

## Database

- PostgreSQL (Supabase)

## Hosting

- Render
- Cloudflare Pages

---

# プロジェクト構成

```text
stock_app
├── backend
│   ├── src
│   ├── Dockerfile
│   ├── pom.xml
│   └── application.yml
│
└── frontend
    ├── lib
    ├── web
    ├── pubspec.yaml
    └── build/web
```

---

# 作業内容

---

# 1. Supabase 構築

## 実施内容

- Supabase プロジェクト作成
- PostgreSQL DB構築
- MySQL → PostgreSQL 移行
- Connection Pooling 設定
- ER確認

---

## 作成済みテーブル

```text
cash_balances
company_profiles
favorites
portfolio_snapshots
positions
stocks
trade_orders
trades
users
```

---

# 2. Spring Boot PostgreSQL 対応

## pom.xml 修正

### PostgreSQL Driver追加

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
```

---

## Lombok annotation processor追加

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.14.0</version>
    <configuration>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>1.18.38</version>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

---

## Spring Boot Main Class設定

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <mainClass>
            com.example.stockapp.StockAppApplication
        </mainClass>
    </configuration>
</plugin>
```

---

# 3. Docker化

## Dockerfile

```dockerfile
FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY . .

RUN chmod +x mvnw
RUN ./mvnw clean package -DskipTests

EXPOSE 8080

CMD ["java", "-jar", "target/stockapp-0.0.1-SNAPSHOT.jar"]
```

---

# 4. Render デプロイ

## Root Directory

```text
stock_app/backend
```

---

## Environment Variables

```text
DATABASE_URL
DATABASE_USERNAME
DATABASE_PASSWORD
JWT_SECRET
MAIL_USERNAME
MAIL_PASSWORD
JQUANTS_API_KEY
```

---

## Supabase接続設定

### DATABASE_URL

```text
jdbc:postgresql://aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres?sslmode=require
```

### DATABASE_USERNAME

```text
postgres.klujfqirzfhtkxitgaoq
```

### DATABASE_PASSWORD

```text
********
```

---

## Backend 公開URL

```text
https://stock-dashboard-api-disc.onrender.com
```

---

# 5. Flutter Web 対応

## API共通化

### api_config.dart

```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
```

---

## localhost API置換

修正前：

```dart
http://localhost:8080
```

修正後：

```dart
ApiConfig.baseUrl
```

---

## Flutter Build

```bash
flutter build web --release --dart-define=API_BASE_URL=https://stock-dashboard-api-disc.onrender.com
```

---

# 6. Cloudflare Pages デプロイ

## Production Branch

```text
0526_Server_Construction
```

---

## Root Directory

```text
stock_app/frontend
```

---

## Build Command

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && export PATH="$PATH:$PWD/flutter/bin" && flutter config --enable-web && flutter pub get && flutter build web --release --dart-define=API_BASE_URL=https://stock-dashboard-api-disc.onrender.com
```

---

## Build Output Directory

```text
build/web
```

---

# Render デプロイ時に対応した問題

## 対応済み

- Lombok annotation processor不足
- Spring Boot mainClass未認識
- StockAppApplication.java リネーム問題
- Docker Build失敗
- PostgreSQL接続失敗
- Supabase Pooler接続失敗
- DATABASE_URL設定ミス
- tenant identifier 問題
- Render Build Cache問題

---

# 現在の状況

## 完了済み

- Supabase DB構築
- Spring Boot PostgreSQL対応
- Docker化
- Render Backend デプロイ成功
- Flutter Web Build 成功
- Cloudflare Pages GitHub連携

---

## 現在対応中

API→DB同期ができない

---

# 原因候補

- Fetch制限

---

# 次回作業予定

- Cloudflare Build Logs確認
- build/web 出力確認
- index.html 配置確認
- Cloudflare 再デプロイ
- Pages Build 成功確認

---

# 公開構成

```text
Flutter Web
  ↓
Cloudflare Pages

Spring Boot API
  ↓
Render

PostgreSQL
  ↓
Supabase
```

---

# Render Buildコマンド

```bash
./mvnw clean package -DskipTests
```

---

# Flutter Web Buildコマンド

```bash
flutter build web --release --dart-define=API_BASE_URL=https://stock-dashboard-api-disc.onrender.com
```

---

# Cloudflare Pages Buildコマンド

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && export PATH="$PATH:$PWD/flutter/bin" && flutter config --enable-web && flutter pub get && flutter build web --release --dart-define=API_BASE_URL=https://stock-dashboard-api-disc.onrender.com
```