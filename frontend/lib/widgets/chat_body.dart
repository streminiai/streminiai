import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';

class ChatBody extends ConsumerWidget {
  const ChatBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider);

    return Expanded(
      child: chatState.when(
        data: (messages) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) => MessageBubble(message: messages[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stremini_chatbot/providers/chat_provider.dart';
import 'package:stremini_chatbot/widgets/message_bubble.dart';

class ChatBody extends ConsumerWidget {
  const ChatBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatNotifierProvider);
    return messages.when(
      data: (data) {
        return Expanded(
          child: ListView.builder(
            // reverse: true,
            padding: const EdgeInsets.all(8.0),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final message = data[index];
              return MessageBubble(message: message);
            },
          ),
        );
      },
      error: (error, stackTrace) => Expanded(
        child: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      loading: () => Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
