class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': content,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String,
      isUser: json['role'] == 'user',
      timestamp: DateTime.now(),
    );
  }
}
