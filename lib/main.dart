import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Colors
const Color electricNeonBlue = Color(0xFF00F0FF);
const Color inactiveGray = Color(0xFF3A3A3C);

// Overlay entry point - runs in separate isolate
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StreminiApp());
}

class StreminiApp extends StatelessWidget {
  const StreminiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stremini AI',
      theme: AppTheme.darkTheme,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== OVERLAY WIDGET ====================
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget>
    with TickerProviderStateMixin {
  // Menu state
  bool _isMenuOpen = false;

  // Feature states - icons turn blue when active
  bool _isChatbotActive = false;
  bool _isScamDetectorActive = false;

  // UI states
  bool _isChatOpen = false;
  bool _isAnalyzing = false;
  bool _showScanResults = false;
  String _scanResultText = '';
  String _scanSafetyLevel = 'safe';

  // Chat
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isSending = false;

  // Animation
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Toggle chatbot - blue when active
  void _toggleChatbot() {
    setState(() {
      if (_isChatbotActive) {
        _isChatbotActive = false;
        _isChatOpen = false;
      } else {
        _isChatbotActive = true;
        _isChatOpen = true;
      }
      _isMenuOpen = false;
    });
  }

  // Close chat via X button
  void _closeChat() {
    setState(() {
      _isChatOpen = false;
      _isChatbotActive = false;
    });
  }

  // Toggle scam detector - blue when active
  void _toggleScamDetector() async {
    if (_isScamDetectorActive) {
      // Deactivate
      setState(() {
        _isScamDetectorActive = false;
        _showScanResults = false;
        _isMenuOpen = false;
      });
    } else {
      // Activate and scan
      setState(() {
        _isScamDetectorActive = true;
        _isAnalyzing = true;
        _isMenuOpen = false;
      });
      await _performScan();
    }
  }

  Future<void> _performScan() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final resp = await http.post(
        Uri.parse('https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/security/scan-content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': 'Screen content analysis request'}),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final safety = (data['safety'] ?? 'Safe').toString();
        final reason = (data['reason'] ?? 'Analysis complete').toString();

        String level = 'safe';
        if (safety.toLowerCase().contains('scam') ||
            safety.toLowerCase().contains('phishing')) {
          level = 'scam';
        } else if (safety.toLowerCase().contains('warning') ||
            safety.toLowerCase().contains('suspicious')) {
          level = 'warning';
        }

        setState(() {
          _isAnalyzing = false;
          _showScanResults = true;
          _scanResultText = '$safety\n$reason';
          _scanSafetyLevel = level;
        });
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _showScanResults = true;
        _scanResultText = 'Error: Could not analyze screen';
        _scanSafetyLevel = 'warning';
      });
    }
  }

  Future<void> _sendMessage() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMsg(text: msg, isUser: true));
      _isSending = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final resp = await http.post(
        Uri.parse('https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': msg}),
      ).timeout(const Duration(seconds: 30));

      String reply = 'Sorry, could not get response.';
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        reply = data['response'] ?? data['text'] ?? data['message'] ?? reply;
      }
      setState(() => _messages.add(_ChatMsg(text: reply, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(_ChatMsg(text: 'Error: $e', isUser: false)));
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _hasActiveFeature() => _isChatbotActive || _isScamDetectorActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Scan results overlay
          if (_showScanResults && _isScamDetectorActive) _buildScanResultTag(),

          // Scanning animation
          if (_isAnalyzing) _buildScanningOverlay(),

          // Chat window
          if (_isChatOpen) _buildChatWindow(),

          // Menu background
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isMenuOpen = false),
                child: Container(color: Colors.black38),
              ),
            ),

          // Menu buttons
          if (_isMenuOpen) ...[
            _buildMenuBtn(
              bottom: 200,
              icon: Icons.chat_bubble_rounded,
              label: 'AI Chatbot',
              isActive: _isChatbotActive,
              onTap: _toggleChatbot,
            ),
            _buildMenuBtn(
              bottom: 140,
              icon: Icons.screen_search_desktop_rounded,
              label: 'Scan Screen',
              isActive: _isScamDetectorActive,
              onTap: _toggleScamDetector,
            ),
            _buildMenuBtn(
              bottom: 80,
              icon: Icons.close_rounded,
              label: 'Close Bubble',
              isActive: false,
              onTap: () => FlutterOverlayWindow.closeOverlay(),
              isClose: true,
            ),
          ],

          // Main bubble
          Positioned(
            right: 12,
            bottom: 20,
            child: GestureDetector(
              onTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, child) {
                  final glow = _hasActiveFeature() || _isAnalyzing;
                  return Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: glow
                            ? [electricNeonBlue, const Color(0xFF0080FF)]
                            : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (glow ? electricNeonBlue : const Color(0xFF3B82F6))
                              .withOpacity(0.4 + _pulseAnim.value * 0.2),
                          blurRadius: 16 + _pulseAnim.value * 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isAnalyzing
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            _isMenuOpen ? Icons.close : Icons.auto_awesome,
                            color: Colors.white,
                            size: 26,
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn({
    required double bottom,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return Positioned(
      right: 12,
      bottom: bottom,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? electricNeonBlue.withOpacity(0.6) : Colors.white24,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? electricNeonBlue : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClose
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : isActive
                          ? [electricNeonBlue, const Color(0xFF0080FF)]
                          : [inactiveGray, const Color(0xFF2A2A2C)],
                ),
                shape: BoxShape.circle,
                border: isActive && !isClose
                    ? Border.all(color: electricNeonBlue, width: 2)
                    : null,
                boxShadow: isActive && !isClose
                    ? [BoxShadow(color: electricNeonBlue.withOpacity(0.5), blurRadius: 12)]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (ctx, _) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: electricNeonBlue.withOpacity(0.3 + _pulseAnim.value * 0.3),
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: electricNeonBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: electricNeonBlue,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Scanning screen...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanResultTag() {
    Color c;
    IconData ic;
    switch (_scanSafetyLevel) {
      case 'scam':
        c = const Color(0xFFEF4444);
        ic = Icons.dangerous;
        break;
      case 'warning':
        c = const Color(0xFFF59E0B);
        ic = Icons.warning;
        break;
      default:
        c = const Color(0xFF10B981);
        ic = Icons.check_circle;
    }

    return Positioned(
      left: 16,
      right: 80,
      top: 100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 16)],
        ),
        child: Row(
          children: [
            Icon(ic, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _scanResultText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showScanResults = false),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 90,
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: electricNeonBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [electricNeonBlue, Color(0xFF0080FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Stremini AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _headerBtn(Icons.open_in_full, () {
                    FlutterOverlayWindow.shareData('fullscreen_chat');
                  }),
                  const SizedBox(width: 6),
                  _headerBtn(Icons.drag_indicator, null),
                  const SizedBox(width: 6),
                  _headerBtn(Icons.close, _closeChat),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) => _chatBubble(_messages[i]),
                    ),
            ),

            // Typing
            if (_isSending)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: electricNeonBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Typing...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),

            // Input
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [electricNeonBlue, Color(0xFF0080FF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  Widget _chatBubble(_ChatMsg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!m.isUser)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [electricNeonBlue, Color(0xFF0080FF)],
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: m.isUser
                    ? electricNeonBlue.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: m.isUser
                    ? Border.all(color: electricNeonBlue.withOpacity(0.3))
                    : null,
              ),
              child: Text(
                m.text,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}
