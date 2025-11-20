import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class ChatNotifier extends AsyncNotifier<List<Message>> {
  // 1. Define the constant ID here to avoid typos
  static const String _initialGreetingId = 'initial_greeting';

  @override
  FutureOr<List<Message>> build() {
    return [
      Message(
        // 2. Use the constant ID here
        id: _initialGreetingId,
        text: "Hello! I'm Stremini AI. How can I help you today?",
        type: MessageType.bot,
        timestamp: DateTime.now(),
      )
    ];
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    // 3. Now this filter logic will actually work
    final current = state.value ?? <Message>[];
    final filtered = current.where((m) => m.id != _initialGreetingId).toList();

    state = AsyncValue.data([...filtered, userMessage]);

    addTypingIndicator();

    try {
      // Ensure apiServiceProvider is defined in your project
      final api = ref.read(apiServiceProvider);
      final reply = await api.sendMessage(trimmed);

      removeTypingIndicator();

      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: reply,
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );

      // Re-read state.value to ensure we keep messages added during the await
      final updated = <Message>[...(state.value ?? []), botMessage];
      state = AsyncValue.data(updated);
    } catch (e) {
      removeTypingIndicator();
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '⚠️ Network or decoding error: $e',
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );

      state = AsyncValue.data([...(state.value ?? []), errorMessage]);
    }
  }

  void addTypingIndicator() {
    final typingMessage = Message(
      id: 'typing_indicator', // Hardcoding this prevents duplicates easier
      text: '...',
      type: MessageType.typing,
      timestamp: DateTime.now(),
    );

    // Avoid adding duplicate typing indicators
    final current = state.value ?? <Message>[];
    if (current.any((m) => m.type == MessageType.typing)) return;

    state = AsyncValue.data([...current, typingMessage]);
  }

  void removeTypingIndicator() {
    final current = state.value ?? <Message>[];
    final filtered =
        current.where((m) => m.type != MessageType.typing).toList();
    state = AsyncValue.data(filtered);
  }
}

final chatNotifierProvider =
    AsyncNotifierProvider<ChatNotifier, List<Message>>(ChatNotifier.new);
