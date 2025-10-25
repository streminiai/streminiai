import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/drawer_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).addMessage(text, MessageType.user);
      _textController.clear();
      
      // Simulate AI response
      Future.delayed(const Duration(seconds: 1), () {
        ref.read(chatProvider.notifier).addTypingIndicator();
        
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(chatProvider.notifier).removeTypingIndicator();
          ref.read(chatProvider.notifier).addMessage(
            "Thanks for asking! Here's my perspective on this topic.",
            MessageType.ai,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAttachmentOptions = ref.watch(attachmentOptionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF3A3A3A)),
        ),
      ),
      child: Column(
        children: [
          if (showAttachmentOptions) _buildAttachmentOptions(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(attachmentOptionsProvider.notifier).toggleAttachmentOptions();
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: Implement voice recording
                },
                icon: const Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: () {
              // TODO: Implement camera functionality
              ref.read(attachmentOptionsProvider.notifier).closeAttachmentOptions();
            },
          ),
          _buildAttachmentOption(
            icon: Icons.photo,
            label: 'Photo',
            onTap: () {
              // TODO: Implement photo picker functionality
              ref.read(attachmentOptionsProvider.notifier).closeAttachmentOptions();
            },
          ),
          _buildAttachmentOption(
            icon: Icons.attach_file,
            label: 'Document',
            onTap: () {
              // TODO: Implement document picker functionality
              ref.read(attachmentOptionsProvider.notifier).closeAttachmentOptions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
