import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('確認ダイアログを表示して閉じられる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('確認'),
                        content: const Text('注文しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('注文確認'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('注文確認'));
    await tester.pumpAndSettle();

    expect(find.text('確認'), findsOneWidget);
    expect(find.text('注文しますか？'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('確認'), findsNothing);
  });
}