import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_body.dart';
import 'message_input.dart';
import '../providers/chat_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../utils/overlay_controller.dart';

class FloatingChatWidget extends ConsumerStatefulWidget {
  const FloatingChatWidget({super.key});

  @override
  ConsumerState<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends ConsumerState<FloatingChatWidget> {
  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(chatExpandedProvider);

    return Positioned(
      bottom: 20,
      right: 20,
      child: isExpanded ? _buildExpandedWidget() : _buildMinimizedWidget(),
    );
  }

  Widget _buildMinimizedWidget() {
    return GestureDetector(
      onTap: () {
        ref.read(chatExpandedProvider.notifier).expand();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildExpandedWidget() {
    return Container(
      width: 380,
      height: 600,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 40,
        maxHeight: MediaQuery.of(context).size.height - 40,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Column(
                children: [
                  const Expanded(child: ChatBody()),
                  const MessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Stremini AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Minimize in-app widget and show system overlay bubble
                ref.read(chatExpandedProvider.notifier).minimize();
                OverlayController.showBubble();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
