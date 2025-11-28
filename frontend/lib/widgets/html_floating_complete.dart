// Save this file as: lib/widgets/html_floating_complete.dart
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
// SCAN TAG MODEL
// ========================================
class ScanTag {
  final String id;
  final Offset position;
  final String tag;
  final Color color;
  final String reason;

  ScanTag({
    required this.id,
    required this.position,
    required this.tag,
    required this.color,
    required this.reason,
  });
}

// ========================================
// STATE MODEL
// ========================================
class HtmlFloatingState {
  final bool bubbleVisible;
  final bool radialMenuOpen;
  final bool chatboxOpen;
  final bool scannerActive;
  final bool scanning;
  final Offset bubblePosition;
  final List<FloatingMessage> messages;
  final List<ScanTag> scanTags;
  final bool isLoading;
  final String? scanError;

  HtmlFloatingState({
    this.bubbleVisible = false,
    this.radialMenuOpen = false,
    this.chatboxOpen = false,
    this.scannerActive = false,
    this.scanning = false,
    this.bubblePosition = const Offset(100, 200),
    this.messages = const [],
    this.scanTags = const [],
    this.isLoading = false,
    this.scanError,
  });

  HtmlFloatingState copyWith({
    bool? bubbleVisible,
    bool? radialMenuOpen,
    bool? chatboxOpen,
    bool? scannerActive,
    bool? scanning,
    Offset? bubblePosition,
    List<FloatingMessage>? messages,
    List<ScanTag>? scanTags,
    bool? isLoading,
    String? scanError,
  }) {
    return HtmlFloatingState(
      bubbleVisible: bubbleVisible ?? this.bubbleVisible,
      radialMenuOpen: radialMenuOpen ?? this.radialMenuOpen,
      chatboxOpen: chatboxOpen ?? this.chatboxOpen,
      scannerActive: scannerActive ?? this.scannerActive,
      scanning: scanning ?? this.scanning,
      bubblePosition: bubblePosition ?? this.bubblePosition,
      messages: messages ?? this.messages,
      scanTags: scanTags ?? this.scanTags,
      isLoading: isLoading ?? this.isLoading,
      scanError: scanError,
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
      chatboxOpen: false,
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

  void toggleScanner() async {
    if (state.scannerActive) {
      // Turn off scanner - clear tags
      state = state.copyWith(
        scannerActive: false,
        scanTags: [],
        scanError: null,
        scanning: false,
        radialMenuOpen: false,
      );
    } else {
      // Turn on scanner - start scanning
      await startScanning();
    }
  }

  Future<void> startScanning() async {
    state = state.copyWith(
      scanning: true,
      scannerActive: true,
      scanError: null,
      radialMenuOpen: false,
      scanTags: [],
    );

    try {
      // Simulate scanning duration
      await Future.delayed(const Duration(seconds: 2));
      
      // Demo scan results - In production, this comes from ScreenScannerService
      final demoTags = _generateDemoScanTags();
      
      state = state.copyWith(
        scanning: false,
        scanTags: demoTags,
      );
    } catch (e) {
      state = state.copyWith(
        scanning: false,
        scanError: 'Scan failed: $e',
        scannerActive: false,
      );
    }
  }

  List<ScanTag> _generateDemoScanTags() {
    return [
      ScanTag(
        id: '1',
        position: const Offset(100, 150),
        tag: 'Scam',
        color: const Color(0xFFD32F2F),
        reason: 'Suspicious link detected - URL shortener used',
      ),
      ScanTag(
        id: '2',
        position: const Offset(50, 300),
        tag: 'Urgent',
        color: const Color(0xFFFF5722),
        reason: 'Pressure tactic - "Act now" language detected',
      ),
      ScanTag(
        id: '3',
        position: const Offset(200, 450),
        tag: 'Safe',
        color: const Color(0xFF4CAF50),
        reason: 'Verified source - Official domain',
      ),
      ScanTag(
        id: '4',
        position: const Offset(150, 600),
        tag: 'Emotional',
        color: const Color(0xFF9C27B0),
        reason: 'Emotional manipulation detected',
      ),
    ];
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
// GRADIENT RING PAINTER (HTML Style)
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
          const Color(0xFF23A6E2).withOpacity(0.5),
          const Color(0xFFAA75F4).withOpacity(0.3),
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
  late AnimationController _scanController;
  late Animation<double> _radialAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scanAnimation;

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

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scanController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _radialController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(htmlFloatingProvider.notifier).sendMessage(text);
    _controller.clear();
    
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

    if (state.radialMenuOpen) {
      _radialController.forward();
    } else {
      _radialController.reverse();
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. SCAN OVERLAY (Scanning animation)
        if (state.scanning) _buildScanningOverlay(),

        // 2. SCAN TAGS (Show after scan completes)
        if (state.scannerActive && !state.scanning && state.scanTags.isNotEmpty)
          ..._buildScanTags(state.scanTags),

        // 3. FLOATING BUBBLE + RADIAL MENU
        Positioned(
          left: state.bubblePosition.dx,
          top: state.bubblePosition.dy,
          child: _buildStreminiWrapper(notifier, screenSize, state),
        ),

        // 4. CHATBOX
        if (state.chatboxOpen) _buildChatbox(notifier, state),
      ],
    );
  }

  // ========================================
  // SCANNING OVERLAY
  // ========================================
  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xFF00D9FF),
                            const Color(0xFFE040FB),
                            _scanAnimation.value,
                          )!,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(
                              const Color(0xFF00D9FF),
                              const Color(0xFFE040FB),
                              _scanAnimation.value,
                            )!.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.radar,
                          color: Color(0xFF00D9FF),
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Scanning Screen...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI is analyzing content for safety',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // SCAN TAGS
  // ========================================
  List<Widget> _buildScanTags(List<ScanTag> tags) {
    return tags.map((tag) {
      return Positioned(
        left: tag.position.dx,
        top: tag.position.dy,
        child: GestureDetector(
          onTap: () => _showTagDetails(tag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tag.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: tag.color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tag.tag == 'Safe' ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  tag.tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showTagDetails(ScanTag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              tag.tag == 'Safe' ? Icons.check_circle : Icons.warning,
              color: tag.color,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              tag.tag,
              style: TextStyle(color: tag.color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          tag.reason,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  // ========================================
  // STREMINI WRAPPER (HTML Style Bubble)
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
            if (state.radialMenuOpen) 
              ..._buildFeatureButtons(notifier, screenSize, state),

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

  Widget _buildLogo() {
    return Container(
      width: 78,
      height: 78,
      child: CustomPaint(
        painter: GradientRingPainter(),
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: const Center(
            child: Icon(
              Icons.email,
              color: Color(0xFFF5F5F5),
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // FEATURE BUTTONS
  // ========================================
  List<Widget> _buildFeatureButtons(
    HtmlFloatingNotifier notifier,
    Size screenSize,
    HtmlFloatingState state,
  ) {
    const double radius = 110.0;
    final isOnRightSide = (state.bubblePosition.dx + 80) > (screenSize.width / 2);

    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.refresh,
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.toggleRadialMenu(),
      },
      {
        'icon': Icons.settings,
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.toggleRadialMenu(),
      },
      {
        'icon': Icons.chat_bubble,
        'color': const Color(0xFF23A6E2),
        'onTap': () => notifier.openChatbox(),
      },
      {
        'icon': Icons.search,
        'color': state.scannerActive ? const Color(0xFF00D9FF) : const Color(0xFFE040FB),
        'onTap': () => notifier.toggleScanner(),
      },
      {
        'icon': Icons.mic,
        'color': const Color(0xFF0066FF),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: items[index]['color'],
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: items[index]['color'].withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    items[index]['icon'],
                    color: items[index]['color'],
                    size: 28,
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
              _buildChatHeader(notifier),
              Expanded(child: _buildMessages(state)),
              _buildChatInput(),
            ],
          ),
        ),
      ),
    );
  }

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF23A6E2),
                  Color(0xFFAA75F4),
                  Color(0xFF0066FF),
                  Color(0xFF23A6E2),
                ],
              ),
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
