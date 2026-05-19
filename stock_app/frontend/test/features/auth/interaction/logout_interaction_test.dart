import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ログアウト押下でログイン画面へ戻る', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const _MyPage(),
          '/login': (_) => const _LoginPage(),
        },
      ),
    );

    expect(find.text('マイページ'), findsOneWidget);

    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();

    expect(find.text('ログイン画面'), findsOneWidget);
  });
}

class _MyPage extends StatelessWidget {
  const _MyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('ログアウト'),
        ),
      ),
    );
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ログイン画面'),
      ),
    );
  }
}