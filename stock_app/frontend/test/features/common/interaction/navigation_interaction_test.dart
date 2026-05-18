import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ボタン押下で画面遷移できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const _HomePage(),
          '/next': (_) => const _NextPage(),
        },
      ),
    );

    expect(find.text('ホーム'), findsOneWidget);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('次の画面'), findsOneWidget);
  });
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/next'),
          child: const Text('次へ'),
        ),
      ),
    );
  }
}

class _NextPage extends StatelessWidget {
  const _NextPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('次の画面')),
    );
  }
}