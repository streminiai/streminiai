import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

// ========================================
// MESSAGE MODEL FOR FLOATING CHAT
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
// STATE MODEL
// ========================================
class WebViewFloatingChatState {
  final bool isVisible;
  final bool showRadialMenu;
  final bool showMiniChat;
  final Offset position;
  final List<FloatingMessage> messages;
  final bool isLoading;

  WebViewFloatingChatState({
    this.isVisible = false,
    this.showRadialMenu = false,
    this.showMiniChat = false,
    this.position = const Offset(100, 200),
    this.messages = const [],
    this.isLoading = false,
  });

  WebViewFloatingChatState copyWith({
    bool? isVisible,
    bool? showRadialMenu,
    bool? showMiniChat,
    Offset? position,
    List<FloatingMessage>? messages,
    bool? isLoading,
  }) {
    return WebViewFloatingChatState(
      isVisible: isVisible ?? this.isVisible,
      showRadialMenu: showRadialMenu ?? this.showRadialMenu,
      showMiniChat: showMiniChat ?? this.showMiniChat,
      position: position ?? this.position,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ========================================
// STATE NOTIFIER
// ========================================
class WebViewFloatingChatNotifier extends Notifier<WebViewFloatingChatState> {
  @override
  WebViewFloatingChatState build() {
    return WebViewFloatingChatState();
  }

  void show() {
    state = state.copyWith(isVisible: true);
  }

  void hide() {
    state = WebViewFloatingChatState();
  }

  void toggleRadialMenu() {
    state = state.copyWith(
      showRadialMenu: !state.showRadialMenu,
      showMiniChat: false,
    );
  }

  void openMiniChat() {
    state = state.copyWith(
      showMiniChat: true,
      showRadialMenu: false,
    );
  }

  void closeMiniChat() {
    state = state.copyWith(showMiniChat: false);
  }

  void updatePosition(Offset newPosition) {
    state = state.copyWith(position: newPosition);
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
final webViewFloatingChatProvider = NotifierProvider<WebViewFloatingChatNotifier, WebViewFloatingChatState>(
  WebViewFloatingChatNotifier.new,
);

// ========================================
// MAIN FLOATING WIDGET (FROM HTML)
// ========================================
class WebViewStyleFloatingChat extends ConsumerStatefulWidget {
  const WebViewStyleFloatingChat({super.key});

  @override
  ConsumerState<WebViewStyleFloatingChat> createState() => _WebViewStyleFloatingChatState();
}

class _WebViewStyleFloatingChatState extends ConsumerState<WebViewStyleFloatingChat>
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
    ref.read(webViewFloatingChatProvider.notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webViewFloatingChatProvider);
    final notifier = ref.read(webViewFloatingChatProvider.notifier);

    if (!state.isVisible) return const SizedBox.shrink();

    // Update animation
    if (state.showRadialMenu) {
      _radialController.forward();
    } else {
      _radialController.reverse();
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Floating Icon with Radial Menu
        Positioned(
          left: state.position.dx,
          top: state.position.dy,
          child: _buildFloatingBubble(notifier, screenSize, state),
        ),

        // Mini Chatbox (Like HTML version)
        if (state.showMiniChat) _buildMiniChatbox(notifier),
      ],
    );
  }

  // ========================================
  // FLOATING BUBBLE WITH RADIAL MENU
  // ========================================
  Widget _buildFloatingBubble(
    WebViewFloatingChatNotifier notifier,
    Size screenSize,
    WebViewFloatingChatState state,
  ) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!state.showRadialMenu) {
          final newX = (state.position.dx + details.delta.dx)
              .clamp(0.0, screenSize.width - 160);
          final newY = (state.position.dy + details.delta.dy)
              .clamp(0.0, screenSize.height - 160);
          notifier.updatePosition(Offset(newX, newY));
        }
      },
      onPanEnd: (details) {
        // Snap to edge
        final currentX = state.position.dx;
        final snapX = currentX < screenSize.width / 2 ? 0.0 : screenSize.width - 160;
        notifier.updatePosition(Offset(snapX, state.position.dy));
      },
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial Menu Items
            if (state.showRadialMenu) ..._buildRadialMenuItems(notifier, screenSize, state),

            // Main Logo Button
            GestureDetector(
              onTap: () => notifier.toggleRadialMenu(),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    width: 3,
                    color: const Color(0xFF2979FF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00AAFF).withOpacity(0.6),
                      blurRadius: 15,
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRadialMenuItems(
    WebViewFloatingChatNotifier notifier,
    Size screenSize,
    WebViewFloatingChatState state,
  ) {
    const double radius = 70.0;
    final isOnRightSide = (state.position.dx + 80) > (screenSize.width / 2);

    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.message,
        'color': const Color(0xFF448AFF),
        'onTap': () {},
      },
      {
        'icon': Icons.settings,
        'color': const Color(0xFF448AFF),
        'onTap': () {},
      },
      {
        'icon': Icons.chat_bubble,
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.openMiniChat(),
      },
      {
        'icon': Icons.mic,
        'color': const Color(0xFF0066FF),
        'onTap': () {},
      },
      {
        'icon': Icons.refresh,
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.toggleRadialMenu(),
      },
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
                    border: Border.all(
                      color: items[index]['color'],
                      width: 2,
                    ),
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
  // MINI CHATBOX (EXACT HTML STYLE)
  // ========================================
  Widget _buildMiniChatbox(WebViewFloatingChatNotifier notifier) {
    final state = ref.watch(webViewFloatingChatProvider);

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
              // Header
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
                      onPressed: () => notifier.closeMiniChat(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: state.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Start chatting...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.messages.length && state.isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF23A6E2),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('...', style: TextStyle(color: Colors.white)),
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

              // Input Area
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
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF007BFF),
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 14,
                        ),
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
