class AiChatMessage {
  final String text;
  final bool fromUser;

  const AiChatMessage({
    required this.text,
    required this.fromUser,
  });
}

class AiChatResponse {
  final String answer;

  const AiChatResponse({
    required this.answer,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      answer: (json['answer'] ?? '').toString(),
    );
  }
}