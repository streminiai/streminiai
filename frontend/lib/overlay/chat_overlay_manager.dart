import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stremini_chatbot/providers/chat_window_state_provider.dart';
import 'package:stremini_chatbot/screens/chat_screen.dart';
import 'package:stremini_chatbot/widgets/draggable_chat_icon.dart';




class ChatOverlayManager extends ConsumerStatefulWidget {
  final Widget child;
  const ChatOverlayManager({super.key, required this.child});

  @override
  ConsumerState<ChatOverlayManager> createState() => _ChatOverlayManagerState();
}

class _ChatOverlayManagerState extends ConsumerState<ChatOverlayManager> {
  // Persistence for bubble position (should ideally be stored in local storage)
  Offset _bubblePosition = const Offset(20, 200);

  void updatePosition(Offset newPosition) {
    setState(() {
      _bubblePosition = newPosition;
    });
  }

  // Action: Toggles the mode between icon <-> radial
  void cycleOverlayMode() {
    final notifier = ref.read(chatWindowStateProvider.notifier);
    final currentMode = ref.read(chatWindowStateProvider).overlayMode;

    if (currentMode == "icon") {
      notifier.setMode("radial");
    } else if (currentMode == "radial") {
      notifier.setMode("icon");
    }
  }

  // Action: Opens the maximized chat window
  void openMaximizedChat() {
    ref.read(chatWindowStateProvider.notifier).setMode("maximized");
  }

  // Action: Closes the maximized chat window (returns to radial mode)
  void closeMaximizedChat() {
    ref.read(chatWindowStateProvider.notifier).setMode("radial");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatWindowStateProvider);
    final isMaximized = state.overlayMode == "maximized";

    return Stack(
      children: [
        // 1. The main application content (Navigator)
        widget.child,

        // 2. The Floating Chat Icon/Menu
        if (!isMaximized) _buildFloatingChat(state.overlayMode),

        // 3. The Maximized Chat Window
        if (isMaximized) _buildMaximizedChat(context),
      ],
    );
  }

  Widget _buildFloatingChat(String mode) {
    return DraggableChatIcon(
      position: _bubblePosition,
      onDragEnd: updatePosition,
      overlayMode: mode,
      onTapMain: cycleOverlayMode,
      onOpenApp: openMaximizedChat,
    );
  }

  Widget _buildMaximizedChat(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Stack(
        children: [
          const ChatScreen(), // Your actual chat screen widget
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: closeMaximizedChat,
            ),
          ),
        ],
      ),
    );
  }
}
