import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/ai_advisor_repository.dart';
import '../domain/ai_chat_models.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    super.key,
    this.stockCode,
  });

  final String? stockCode;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<AiChatMessage> _messages = [
    AiChatMessage(
      fromUser: false,
      text: widget.stockCode == null || widget.stockCode!.isEmpty
          ? 'こんにちは。株価・保有銘柄・疑似売買について相談できます。'
          : 'こんにちは。銘柄コード ${widget.stockCode} の情報を使って相談できます。',
    ),
  ];

  bool _sending = false;

  @override
  void dispose() {
    _repository.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(AiChatMessage(text: text, fromUser: true));
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final res = await _repository.sendChatMessage(
        text,
        stockCode: widget.stockCode,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(AiChatMessage(text: res.answer, fromUser: false));
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const AiChatMessage(
            text: 'AI接続に失敗しました。Ollamaが起動しているか確認してください。',
            fromUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasStockCode = widget.stockCode != null && widget.stockCode!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          hasStockCode ? 'AIチャット ${widget.stockCode}' : 'AIチャット',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (hasStockCode) {
              context.go('/stock/${widget.stockCode}');
            } else {
              context.go('/ai-advisor');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (hasStockCode)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '銘柄コード ${widget.stockCode} の情報をAIに渡して回答します。',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  return _ChatBubble(message: m);
                },
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: hasStockCode
                            ? '例：この銘柄の注意点を教えて'
                            : '例：保有銘柄のリスクを教えて',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 52,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
  });

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isUser
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}