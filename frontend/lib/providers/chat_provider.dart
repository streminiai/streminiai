import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([
    const ChatMessage(
      id: '1',
      content: "Hello! I'm Stremini AI. How can I help you today?",
      type: MessageType.ai,
      timestamp: null,
    ),
  ]);

  void addMessage(String content, MessageType type) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      timestamp: DateTime.now(),
    );
    state = [...state, message];
  }

  void addTypingIndicator() {
    final typingMessage = ChatMessage(
      id: 'typing',
      content: '',
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = [...state, typingMessage];
  }

  void removeTypingIndicator() {
    state = state.where((message) => !message.isTyping).toList();
  }

  void clearChat() {
    state = [
      const ChatMessage(
        id: '1',
        content: "Hello! I'm Stremini AI. How can I help you today?",
        type: MessageType.ai,
        timestamp: null,
      ),
    ];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});
