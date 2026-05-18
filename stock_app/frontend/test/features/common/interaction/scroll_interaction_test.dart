import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('一覧をスクロールできる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('銘柄 $index'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('銘柄 0'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('銘柄 20'),
      300,
      scrollable: find.byType(Scrollable),
    );

    await tester.pumpAndSettle();

    expect(find.text('銘柄 20'), findsOneWidget);
  });
}