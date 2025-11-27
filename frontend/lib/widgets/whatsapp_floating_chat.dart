import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Enhanced Floating Chatbot State
class FloatingChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? id;

  FloatingChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
  });
}

class EnhancedFloatingChatState {
  final bool isVisible;
  final bool isExpanded;
  final bool isMinimized;
  final Offset position;
  final List<FloatingChatMessage> messages;
  final bool isLoading;
  final bool isDragging;

  EnhancedFloatingChatState({
    this.isVisible = false,
    this.isExpanded = false,
    this.isMinimized = false,
    this.position = const Offset(20, 100),
    this.messages = const [],
    this.isLoading = false,
    this.isDragging = false,
  });

  EnhancedFloatingChatState copyWith({
    bool? isVisible,
    bool? isExpanded,
    bool? isMinimized,
    Offset? position,
    List<FloatingChatMessage>? messages,
    bool? isLoading,
    bool? isDragging,
  }) {
    return EnhancedFloatingChatState(
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
      isMinimized: isMinimized ?? this.isMinimized,
      position: position ?? this.position,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

class EnhancedFloatingChatNotifier extends Notifier<EnhancedFloatingChatState> {
  @override
  EnhancedFloatingChatState build() {
    return EnhancedFloatingChatState();
  }

  void show() {
    state = state.copyWith(isVisible: true, isExpanded: false);
  }

  void hide() {
    state = EnhancedFloatingChatState();
  }

  void toggleExpand() {
    state = state.copyWith(
      isExpanded: !state.isExpanded,
      isMinimized: false,
    );
  }

  void minimize() {
    state = state.copyWith(
      isExpanded: false,
      isMinimized: true,
    );
  }

  void maximize() {
    state = state.copyWith(
      isExpanded: true,
      isMinimized: false,
    );
  }

  void updatePosition(Offset newPosition) {
    state = state.copyWith(position: newPosition);
  }

  void setDragging(bool dragging) {
    state = state.copyWith(isDragging: dragging);
  }

  void addMessage(String text, bool isUser) {
    final newMessage = FloatingChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    state = state.copyWith(
      messages: [...state.messages, newMessage],
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    addMessage(text, true);
    setLoading(true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.sendMessage(text);
      addMessage(response, false);
    } catch (e) {
      addMessage("Sorry, I couldn't process your message. Please try again.", false);
    } finally {
      setLoading(false);
    }
  }
}

final enhancedFloatingChatProvider = NotifierProvider<EnhancedFloatingChatNotifier, EnhancedFloatingChatState>(
  EnhancedFloatingChatNotifier.new,
);

// WhatsApp-Style Floating Chatbot Widget
class WhatsAppStyleFloatingChat extends ConsumerStatefulWidget {
  const WhatsAppStyleFloatingChat({super.key});

  @override
  ConsumerState<WhatsAppStyleFloatingChat> createState() => _WhatsAppStyleFloatingChatState();
}

class _WhatsAppStyleFloatingChatState extends ConsumerState<WhatsAppStyleFloatingChat>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(enhancedFloatingChatProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enhancedFloatingChatProvider);
    final notifier = ref.read(enhancedFloatingChatProvider.notifier);

    if (!state.isVisible) return const SizedBox.shrink();

    // Trigger animation when expanded
    if (state.isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Backdrop when expanded
        if (state.isExpanded)
          GestureDetector(
            onTap: () => notifier.minimize(),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

        // Floating Icon or Expanded Chat
        Positioned(
          left: state.isExpanded ? 0 : state.position.dx,
          top: state.isExpanded ? 0 : state.position.dy,
          right: state.isExpanded ? 0 : null,
          bottom: state.isExpanded ? 0 : null,
          child: state.isExpanded
              ? _buildExpandedChat(notifier)
              : _buildFloatingIcon(notifier, screenSize),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(EnhancedFloatingChatNotifier notifier, Size screenSize) {
    return GestureDetector(
      onPanStart: (_) => notifier.setDragging(true),
      onPanUpdate: (details) {
        final newPosition = Offset(
          (ref.read(enhancedFloatingChatProvider).position.dx + details.delta.dx)
              .clamp(0, screenSize.width - 60),
          (ref.read(enhancedFloatingChatProvider).position.dy + details.delta.dy)
              .clamp(0, screenSize.height - 60),
        );
        notifier.updatePosition(newPosition);
      },
      onPanEnd: (details) {
        notifier.setDragging(false);
        // Snap to nearest edge
        final currentX = ref.read(enhancedFloatingChatProvider).position.dx;
        final snapX = currentX < screenSize.width / 2 ? 20.0 : screenSize.width - 80;
        notifier.updatePosition(Offset(snapX, ref.read(enhancedFloatingChatProvider).position.dy));
      },
      onTap: () => notifier.toggleExpand(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [Color(0xFF25D366), Color(0xFF128C7E), Color(0xFF075E54)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            // Unread badge
            if (ref.watch(enhancedFloatingChatProvider).messages.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ref.watch(enhancedFloatingChatProvider).messages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChat(EnhancedFloatingChatNotifier notifier) {
    final state = ref.watch(enhancedFloatingChatProvider);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B141A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildChatHeader(notifier),
              
              // Messages
              Expanded(
                child: _buildMessagesList(state),
              ),
              
              // Input
              _buildChatInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader(EnhancedFloatingChatNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stremini AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => notifier.clearMessages(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => notifier.hide(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(EnhancedFloatingChatState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
          ),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.messages.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.messages.length && state.isLoading) {
            return _buildTypingIndicator();
          }

          final message = state.messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(FloatingChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF005C4B)
                    : const Color(0xFF1F2C34),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: message.isUser
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: message.isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
