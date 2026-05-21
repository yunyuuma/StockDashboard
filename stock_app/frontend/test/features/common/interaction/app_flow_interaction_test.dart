import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ログイン後の主要画面遷移フローを確認できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (_) => const _LoginMockPage(),
          '/stocks': (_) => const _StockListMockPage(),
          '/ai': (_) => const _AiMockPage(),
        },
      ),
    );

    expect(find.text('ログイン'), findsOneWidget);

    await tester.tap(find.text('ログインする'));
    await tester.pumpAndSettle();

    expect(find.text('銘柄一覧'), findsOneWidget);

    await tester.tap(find.text('AI相談'));
    await tester.pumpAndSettle();

    expect(find.text('AIチャット'), findsOneWidget);
  });
}

class _LoginMockPage extends StatelessWidget {
  const _LoginMockPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/stocks'),
          child: const Text('ログインする'),
        ),
      ),
    );
  }
}

class _StockListMockPage extends StatelessWidget {
  const _StockListMockPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('銘柄一覧')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/ai'),
          child: const Text('AI相談'),
        ),
      ),
    );
  }
}

class _AiMockPage extends StatelessWidget {
  const _AiMockPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIチャット')),
      body: const Text('AI画面'),
    );
  }
}