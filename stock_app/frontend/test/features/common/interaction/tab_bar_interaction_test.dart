import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TabBarを切り替えできる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: TabBar(
              tabs: [
                Tab(text: '概要'),
                Tab(text: 'チャート'),
                Tab(text: 'ニュース'),
              ],
            ),
            body: TabBarView(
              children: [
                Center(child: Text('概要画面')),
                Center(child: Text('チャート画面')),
                Center(child: Text('ニュース画面')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('概要画面'), findsOneWidget);

    await tester.tap(find.text('チャート'));
    await tester.pumpAndSettle();
    expect(find.text('チャート画面'), findsOneWidget);

    await tester.tap(find.text('ニュース'));
    await tester.pumpAndSettle();
    expect(find.text('ニュース画面'), findsOneWidget);
  });
}