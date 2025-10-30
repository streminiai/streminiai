import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class ChatNotifier extends AsyncNotifier<List<Message>> {
  @override
  FutureOr<List<Message>> build() {
    // initial chat message from the bot
    return [
      Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Hello! I'm Stremini AI. How can I help you today?",
        type: MessageType.bot,
        timestamp: DateTime.now(),
      )
    ];
  }

  /// Sends a user message, shows a typing indicator, calls the API service,
  /// and appends the bot reply (or an error message) to the chat state.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    // Append user message
    final current = state.value ?? <Message>[];
    state = AsyncValue.data([...current, userMessage]);

    // Show typing indicator
    addTypingIndicator();

    try {
      final api = ref.read(apiServiceProvider);
      final reply = await api.sendMessage(trimmed);

      // Remove typing indicator
      removeTypingIndicator();

      // Append bot reply
      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: reply,
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );

      final updated = <Message>[...(state.value ?? []), botMessage];
      state = AsyncValue.data(updated);
    } catch (e) {
      // On error, remove typing and show an error message from the bot
      removeTypingIndicator();
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '⚠️ Network or decoding error: $e',
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );

      final updated = <Message>[...(state.value ?? []), errorMessage];
      state = AsyncValue.data(updated);
    }
  }

  void addTypingIndicator() {
    final typingMessage = Message(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      type: MessageType.typing,
      timestamp: DateTime.now(),
    );

    final current = state.value ?? <Message>[];
    state = AsyncValue.data([...current, typingMessage]);
  }

  void removeTypingIndicator() {
    final current = state.value ?? <Message>[];
    final filtered =
        current.where((m) => m.type != MessageType.typing).toList();
    state = AsyncValue.data(filtered);
  }
}

/// Provider to read/write chat messages.
final chatNotifierProvider =
    AsyncNotifierProvider<ChatNotifier, List<Message>>(ChatNotifier.new);
