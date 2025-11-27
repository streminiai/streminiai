import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

// ========================================
// MESSAGE MODEL
// ========================================
class FloatingMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  FloatingMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ========================================
// STATE MODEL (EXACT HTML REPLICA)
// ========================================
class HtmlFloatingState {
  final bool bubbleVisible;
  final bool radialMenuOpen;
  final bool chatboxOpen;
  final Offset bubblePosition;
  final List<FloatingMessage> messages;
  final bool isLoading;

  HtmlFloatingState({
    this.bubbleVisible = true,
    this.radialMenuOpen = false,
    this.chatboxOpen = false,
    this.bubblePosition = const Offset(100, 200),
    this.messages = const [],
    this.isLoading = false,
  });

  HtmlFloatingState copyWith({
    bool? bubbleVisible,
    bool? radialMenuOpen,
    bool? chatboxOpen,
    Offset? bubblePosition,
    List<FloatingMessage>? messages,
    bool? isLoading,
  }) {
    return HtmlFloatingState(
      bubbleVisible: bubbleVisible ?? this.bubbleVisible,
      radialMenuOpen: radialMenuOpen ?? this.radialMenuOpen,
      chatboxOpen: chatboxOpen ?? this.chatboxOpen,
      bubblePosition: bubblePosition ?? this.bubblePosition,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ========================================
// STATE NOTIFIER
// ========================================
class HtmlFloatingNotifier extends Notifier<HtmlFloatingState> {
  @override
  HtmlFloatingState build() {
    return HtmlFloatingState();
  }

  void showBubble() {
    state = state.copyWith(bubbleVisible: true);
  }

  void hideBubble() {
    state = HtmlFloatingState();
  }

  void toggleRadialMenu() {
    state = state.copyWith(
      radialMenuOpen: !state.radialMenuOpen,
    );
  }

  void openChatbox() {
    state = state.copyWith(
      chatboxOpen: true,
      radialMenuOpen: false,
    );
  }

  void closeChatbox() {
    state = state.copyWith(chatboxOpen: false);
  }

  void updateBubblePosition(Offset newPosition) {
    state = state.copyWith(bubblePosition: newPosition);
  }

  void addMessage(String text, bool isUser) {
    final newMessage = FloatingMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(text, true);
    setLoading(true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.sendMessage(text);
      addMessage(response, false);
    } catch (e) {
      addMessage("Sorry, I couldn't process your message.", false);
    } finally {
      setLoading(false);
    }
  }
}

// ========================================
// PROVIDER
// ========================================
final htmlFloatingProvider = NotifierProvider<HtmlFloatingNotifier, HtmlFloatingState>(
  HtmlFloatingNotifier.new,
);

// ========================================
// MAIN WIDGET - EXACT HTML REPLICA
// ========================================
class HtmlStyleFloatingChat extends ConsumerStatefulWidget {
  const HtmlStyleFloatingChat({super.key});

  @override
  ConsumerState<HtmlStyleFloatingChat> createState() => _HtmlStyleFloatingChatState();
}

class _HtmlStyleFloatingChatState extends ConsumerState<HtmlStyleFloatingChat>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _radialController;
  late Animation<double> _radialAnimation;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _radialAnimation = CurvedAnimation(
      parent: _radialController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _radialController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(htmlFloatingProvider.notifier).sendMessage(text);
    _controller.clear();
    
    // Auto-scroll
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(htmlFloatingProvider);
    final notifier = ref.read(htmlFloatingProvider.notifier);

    if (!state.bubbleVisible) return const SizedBox.shrink();

    // Update animation
    if (state.radialMenuOpen) {
      _radialController.forward();
    } else {
      _radialController.reverse();
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. FLOATING BUBBLE + RADIAL MENU (Always visible)
        Positioned(
          left: state.bubblePosition.dx,
          top: state.bubblePosition.dy,
          child: _buildStreminiWrapper(notifier, screenSize, state),
        ),

        // 2. CHATBOX (Opens when AI button clicked)
        if (state.chatboxOpen) _buildChatbox(notifier, state),
      ],
    );
  }

  // ========================================
  // STREMINI WRAPPER (Bubble + Radial Menu)
  // ========================================
  Widget _buildStreminiWrapper(
    HtmlFloatingNotifier notifier,
    Size screenSize,
    HtmlFloatingState state,
  ) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!state.radialMenuOpen) {
          final newX = (state.bubblePosition.dx + details.delta.dx)
              .clamp(0.0, screenSize.width - 160);
          final newY = (state.bubblePosition.dy + details.delta.dy)
              .clamp(0.0, screenSize.height - 160);
          notifier.updateBubblePosition(Offset(newX, newY));
        }
      },
      onPanEnd: (details) {
        // Snap to edge
        final currentX = state.bubblePosition.dx;
        final snapX = currentX < screenSize.width / 2 
            ? 0.0 
            : screenSize.width - 160;
        notifier.updateBubblePosition(Offset(snapX, state.bubblePosition.dy));
      },
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Feature Buttons (Radial Menu)
            if (state.radialMenuOpen) 
              ..._buildFeatureButtons(notifier, screenSize, state),

            // Logo (Center)
            GestureDetector(
              onTap: () => notifier.toggleRadialMenu(),
              child: _buildLogo(),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // LOGO (Center Bubble)
  // ========================================
  Widget _buildLogo() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AAFF).withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFF23A6E2),
              Color(0xFFAA75F4),
              Color(0xFF0066FF),
            ],
          ),
        ),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ========================================
  // FEATURE BUTTONS (5 Radial Items)
  // ========================================
  List<Widget> _buildFeatureButtons(
    HtmlFloatingNotifier notifier,
    Size screenSize,
    HtmlFloatingState state,
  ) {
    const double radius = 70.0;
    final isOnRightSide = (state.bubblePosition.dx + 80) > (screenSize.width / 2);

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.refresh, 'color': const Color(0xFF23A6E2)},
      {'icon': Icons.settings, 'color': const Color(0xFF23A6E2)},
      {
        'icon': Icons.chat_bubble, 
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.openChatbox(), // Open chatbox
      },
      {'icon': Icons.search, 'color': const Color(0xFFE040FB)},
      {'icon': Icons.mic, 'color': const Color(0xFF0066FF)},
    ];

    final double startAngle = isOnRightSide ? 90.0 : 90.0;
    final double endAngle = isOnRightSide ? 270.0 : -90.0;
    final double step = (endAngle - startAngle) / (items.length - 1);

    return List.generate(items.length, (index) {
      final angle = startAngle + (index * step);
      final rad = angle * (math.pi / 180.0);
      final x = radius * math.cos(rad);
      final y = radius * math.sin(rad);

      return AnimatedBuilder(
        animation: _radialAnimation,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(
              x * _radialAnimation.value,
              -y * _radialAnimation.value,
            ),
            child: Opacity(
              opacity: _radialAnimation.value.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: items[index]['onTap'],
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: items[index]['color'], width: 2),
                  ),
                  child: Icon(
                    items[index]['icon'],
                    color: items[index]['color'],
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ========================================
  // CHATBOX (Mini Chat Window)
  // ========================================
  Widget _buildChatbox(HtmlFloatingNotifier notifier, HtmlFloatingState state) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          height: 480,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFF23A6E2),
                            Color(0xFFAA75F4),
                            Color(0xFF0066FF),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Stremini AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => notifier.closeChatbox(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Chat Messages
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: state.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Ask me anything...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.messages.length && state.isLoading) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF23A6E2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '...',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final message = state.messages[index];
                            return Align(
                              alignment: message.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(maxWidth: 240),
                                decoration: BoxDecoration(
                                  color: message.isUser
                                      ? const Color(0xFF007BFF)
                                      : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  message.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Chat Input
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(
                    top: BorderSide(color: Color(0xFF222222)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Image.network(
                        'https://img.icons8.com/?size=100&id=IW5bIS9JfkRW&format=png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.mic, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
