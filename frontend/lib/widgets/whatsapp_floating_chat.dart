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
// STATE MODEL
// ========================================
class HtmlFloatingState {
  final bool bubbleVisible;
  final bool radialMenuOpen;
  final bool chatboxOpen;
  final Offset bubblePosition;
  final List<FloatingMessage> messages;
  final bool isLoading;

  HtmlFloatingState({
    this.bubbleVisible = false,
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
      chatboxOpen: false, // Close chat when opening radial
    );
  }

  void openChatbox() {
    state = state.copyWith(
      chatboxOpen: true,
      radialMenuOpen: false, // Close radial when opening chat
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
      addMessage("Sorry, I couldn't process your message. Error: $e", false);
    } finally {
      setLoading(false);
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}

// ========================================
// PROVIDER
// ========================================
final htmlFloatingProvider = NotifierProvider<HtmlFloatingNotifier, HtmlFloatingState>(
  HtmlFloatingNotifier.new,
);

// ========================================
// GRADIENT RING PAINTER (EXACT HTML REPLICA)
// ========================================
class GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF23A6E2).withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // Gradient ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF23A6E2),
          Color(0xFFAA75F4),
          Color(0xFF0066FF),
          Color(0xFF23A6E2),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 2));
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Inner black circle
    final innerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// MAIN WIDGET
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
  late Animation<double> _rotationAnimation;

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
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _radialController, curve: Curves.easeInOut),
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
        // 1. FLOATING BUBBLE + RADIAL MENU
        Positioned(
          left: state.bubblePosition.dx,
          top: state.bubblePosition.dy,
          child: _buildStreminiWrapper(notifier, screenSize, state),
        ),

        // 2. CHATBOX
        if (state.chatboxOpen) _buildChatbox(notifier, state),
      ],
    );
  }

  // ========================================
  // STREMINI WRAPPER
  // ========================================
  Widget _buildStreminiWrapper(
    HtmlFloatingNotifier notifier,
    Size screenSize,
    HtmlFloatingState state,
  ) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!state.radialMenuOpen && !state.chatboxOpen) {
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
              child: RotationTransition(
                turns: _rotationAnimation,
                child: _buildLogo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // LOGO WITH GRADIENT RING & GLOW
  // ========================================
  Widget _buildLogo() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AAFF).withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF00AAFF).withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: GradientRingPainter(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: const Center(
            child: Icon(
              Icons.chat,
              color: Colors.white,
              size: 30,
            ),
          ),
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
    const double radius = 110.0;
    final isOnRightSide = (state.bubblePosition.dx + 80) > (screenSize.width / 2);

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.refresh, 'color': const Color(0xFF23A6E2), 'onTap': () {}},
      {'icon': Icons.settings, 'color': const Color(0xFF23A6E2), 'onTap': () {}},
      {
        'icon': Icons.chat_bubble, 
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.openChatbox(),
      },
      {'icon': Icons.search, 'color': const Color(0xFFE040FB), 'onTap': () {}},
      {'icon': Icons.mic, 'color': const Color(0xFF0066FF), 'onTap': () {}},
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
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: items[index]['color'],
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: items[index]['color'].withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    items[index]['icon'],
                    color: items[index]['color'],
                    size: 24,
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
  // CHATBOX
  // ========================================
  Widget _buildChatbox(HtmlFloatingNotifier notifier, HtmlFloatingState state) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 320,
          height: 480,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222222)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00AAFF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Chat Header
              _buildChatHeader(notifier),

              // Chat Messages
              Expanded(
                child: _buildMessages(state),
              ),

              // Chat Input
              _buildChatInput(),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // CHAT HEADER
  // ========================================
  Widget _buildChatHeader(HtmlFloatingNotifier notifier) {
    return Container(
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF23A6E2),
                  Color(0xFFAA75F4),
                  Color(0xFF0066FF),
                  Color(0xFF23A6E2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00AAFF).withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Stremini AI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => notifier.closeChatbox(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ========================================
  // CHAT MESSAGES
  // ========================================
  Widget _buildMessages(HtmlFloatingState state) {
    return Container(
      color: Colors.black,
      child: state.messages.isEmpty
          ? const Center(
              child: Text(
                'Ask me anything...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length && state.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF23A6E2),
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
                      vertical: 10,
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
    );
  }

  // ========================================
  // CHAT INPUT
  // ========================================
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Color(0xFF222222)),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF23A6E2), Color(0xFF0066FF)],
                ),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
