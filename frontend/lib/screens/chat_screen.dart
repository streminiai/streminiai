import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/drawer_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';
import '../widgets/navigation_drawer.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    final isDrawerOpen = ref.watch(drawerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerProvider.notifier).toggleDrawer(),
        ),
        title: const Text('Stremini AI'),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    if (message.isTyping) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: TypingIndicator(),
                      );
                    }
                    return MessageBubble(message: message);
                  },
                ),
              ),
              const ChatInput(),
            ],
          ),
          if (isDrawerOpen)
            const NavigationDrawer(),
        ],
      ),
    );
  }
}
