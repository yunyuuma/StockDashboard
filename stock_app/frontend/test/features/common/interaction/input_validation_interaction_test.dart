import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('未入力時にエラーメッセージを表示できる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ValidationMockPage(),
      ),
    );

    await tester.tap(find.text('送信'));
    await tester.pump();

    expect(find.text('入力してください'), findsOneWidget);
  });

  testWidgets('入力後はエラーメッセージが消える', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ValidationMockPage(),
      ),
    );

    await tester.enterText(find.byType(TextField), '7203');
    await tester.tap(find.text('送信'));
    await tester.pump();

    expect(find.text('入力してください'), findsNothing);
    expect(find.text('送信成功'), findsOneWidget);
  });
}

class _ValidationMockPage extends StatefulWidget {
  const _ValidationMockPage();

  @override
  State<_ValidationMockPage> createState() => _ValidationMockPageState();
}

class _ValidationMockPageState extends State<_ValidationMockPage> {
  final TextEditingController _controller = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _message = _controller.text.trim().isEmpty ? '入力してください' : '送信成功';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _controller),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('送信'),
          ),
          if (_message != null) Text(_message!),
        ],
      ),
    );
  }
}