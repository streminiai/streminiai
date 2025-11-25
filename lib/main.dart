import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/theme/app_theme.dart';
import 'package:stremniapp/services/screen_capture_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  // API Configuration
  static const String _baseUrl = 
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // Services
  final ScreenCaptureService _captureService = ScreenCaptureService();
  
  // Menu state
  bool _isMenuOpen = false;

  // Feature states - icons turn blue when active
  bool _isChatbotActive = false;
  bool _isScamDetectorActive = false;

  // Chat window states
  bool _isChatOpen = false;
  bool _isChatFullscreen = false;
  Offset _chatPosition = const Offset(12, 200);
  bool _isDraggingChat = false;

  // UI states
  bool _isAnalyzing = false;
  List<ContentTag> _contentTags = [];

  // Chat
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isSending = false;

  // Animation
  late AnimationController _pulseAnim;
  late AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanAnim = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Add welcome message
    _messages.add(_ChatMsg(
      text: "Hello! I'm Stremini AI. How can I help you today?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _scanAnim.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Toggle chatbot - blue when active
  void _toggleChatbot() {
    setState(() {
      if (_isChatbotActive) {
        // Deactivate - close chat and turn icon gray
        _isChatbotActive = false;
        _isChatOpen = false;
      } else {
        // Activate - open chat and turn icon blue
        _isChatbotActive = true;
        _isChatOpen = true;
      }
      _isMenuOpen = false;
    });
  }

  // Close chat via X button - also deactivates feature
  void _closeChat() {
    setState(() {
      _isChatOpen = false;
      _isChatbotActive = false; // Turn icon back to gray
    });
  }

  // Toggle fullscreen
  void _toggleFullscreen() {
    setState(() {
      _isChatFullscreen = !_isChatFullscreen;
    });
  }

  // Toggle scam detector - blue when active
  void _toggleScamDetector() async {
    if (_isScamDetectorActive) {
      // Deactivate - remove tags and turn icon gray
      setState(() {
        _isScamDetectorActive = false;
        _contentTags.clear();
        _isMenuOpen = false;
      });
    } else {
      // Activate - scan screen and show tags
      setState(() {
        _isScamDetectorActive = true;
        _isAnalyzing = true;
        _isMenuOpen = false;
      });
      _scanAnim.forward(from: 0);
      await _performScreenScan();
    }
  }

  Future<void> _performScreenScan() async {
    try {
      // Step 1: Capture screen
      await Future.delayed(const Duration(milliseconds: 800));
      
      final captureResult = await _captureService.captureScreenText();
      
      if (!captureResult.success) {
        throw Exception(captureResult.error ?? 'Screen capture failed');
      }

      final extractedText = captureResult.text.trim();
      
      if (extractedText.isEmpty) {
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      // Step 2: Analyze content
      final response = await http.post(
        Uri.parse('$_baseUrl/security/analyze-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': extractedText}),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Analysis timed out'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse response
        final safety = (data['safety'] ?? 'Safe').toString();
        final reason = (data['reason'] ?? '').toString();
        
        // Generate tags based on analysis
        List<ContentTag> tags = [];
        
        if (safety.toLowerCase().contains('scam')) {
          tags.add(ContentTag(
            label: '🚨 SCAM',
            color: const Color(0xFFEF4444),
            position: const Offset(100, 150),
          ));
        } else if (safety.toLowerCase().contains('suspicious')) {
          tags.add(ContentTag(
            label: '⚠️ SUSPICIOUS',
            color: const Color(0xFFF59E0B),
            position: const Offset(100, 150),
          ));
        } else {
          tags.add(ContentTag(
            label: '✅ SAFE',
            color: const Color(0xFF10B981),
            position: const Offset(100, 150),
          ));
        }
        
        // Add emotion/tone tags if available
        if (reason.toLowerCase().contains('urgent')) {
          tags.add(ContentTag(
            label: 'Urgent Tone',
            color: const Color(0xFFF59E0B),
            position: const Offset(100, 220),
          ));
        }

        setState(() {
          _isAnalyzing = false;
          _contentTags = tags;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() {
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    } finally {
      _scanAnim.reset();
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
        Uri.parse('$_baseUrl/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': msg}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      String reply = 'Sorry, could not get response.';
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        reply = data['response'] ?? data['text'] ?? data['message'] ?? reply;
      } else {
        reply = 'Server error: ${resp.statusCode}';
      }
      setState(() => _messages.add(_ChatMsg(text: reply, isUser: false)));
    } on TimeoutException {
      setState(() => _messages.add(_ChatMsg(
        text: 'Request timed out. Please check your internet connection.',
        isUser: false,
      )));
    } catch (e) {
      setState(() => _messages.add(_ChatMsg(
        text: 'Error: ${e.toString()}',
        isUser: false,
      )));
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
          // Content tags overlay (for scam detector)
          if (_contentTags.isNotEmpty && _isScamDetectorActive)
            ..._contentTags.map((tag) => _buildContentTag(tag)),

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
                            _isMenuOpen ? Icons.close : Icons.security,
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
          animation: _scanAnim,
          builder: (ctx, _) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: electricNeonBlue.withOpacity(0.3 + _scanAnim.value * 0.4),
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

  Widget _buildContentTag(ContentTag tag) {
    return Positioned(
      left: tag.position.dx,
      top: tag.position.dy,
      child: GestureDetector(
        onTap: () {
          // Remove tag on tap
          setState(() {
            _contentTags.remove(tag);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tag.color.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: tag.color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            tag.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    final screenSize = MediaQuery.of(context).size;
    
    if (_isChatFullscreen) {
      return Positioned.fill(
        child: Container(
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              _buildChatHeader(),
              Expanded(child: _buildMessagesList()),
              if (_isSending) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: _chatPosition.dx,
      top: _chatPosition.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDraggingChat = true),
        onPanUpdate: (details) {
          setState(() {
            _chatPosition = Offset(
              (_chatPosition.dx + details.delta.dx).clamp(0.0, screenSize.width - 350),
              (_chatPosition.dy + details.delta.dy).clamp(0.0, screenSize.height - 400),
            );
          });
        },
        onPanEnd: (_) => setState(() => _isDraggingChat = false),
        child: Container(
          width: 350,
          height: 400,
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
              _buildChatHeader(),
              Expanded(child: _buildMessagesList()),
              if (_isSending) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          // Move button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.open_with, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Fullscreen button
          GestureDetector(
            onTap: _toggleFullscreen,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isChatFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Close button
          GestureDetector(
            onTap: _closeChat,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) => _chatBubble(_messages[i]),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 4),
      child: Row(
        children: const [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: electricNeonBlue,
            ),
          ),
          SizedBox(width: 8),
          Text('Typing...', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Mic button
          GestureDetector(
            onTap: () {
              // TODO: Implement voice input
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon')),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
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
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [electricNeonBlue, Color(0xFF0080FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
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

class ContentTag {
  final String label;
  final Color color;
  final Offset position;

  ContentTag({
    required this.label,
    required this.color,
    required this.position,
  });
}
