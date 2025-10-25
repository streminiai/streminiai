import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';

class ChatNotifier extends StateNotifier<List<Message>> {
  ChatNotifier() : super([]) {
    // Add initial bot message
    _addInitialMessage();
  }

  void _addInitialMessage() {
    final initialMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Hello! I'm Stremini AI. How can I help you today?",
      type: MessageType.bot,
      timestamp: DateTime.now(),
    );
    state = [initialMessage];
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = [...state, userMessage];
  }

  void addTypingIndicator() {
    final typingMessage = Message(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      type: MessageType.typing,
      timestamp: DateTime.now(),
    );

    state = [...state, typingMessage];
  }

  void removeTypingIndicator() {
    state = state.where((message) => message.type != MessageType.typing).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>((ref) {
  return ChatNotifier();
});
