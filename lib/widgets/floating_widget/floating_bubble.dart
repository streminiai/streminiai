import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'chat_overlay.dart';

class FloatingBubble extends StatefulWidget {
  const FloatingBubble({super.key});

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble> with SingleTickerProviderStateMixin {
  bool _isChatExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the bubble
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for messages from main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == 'close') {
        _closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Chat Interface (when expanded)
          if (_isChatExpanded)
            Positioned.fill(
              child: ChatOverlay(
                onClose: () {
                  setState(() {
                    _isChatExpanded = false;
                  });
                },
              ),
            ),

          // Floating Bubble (when collapsed)
          if (!_isChatExpanded)
            Positioned(
              right: 16,
              bottom: 100,
              child: GestureDetector(
                onTap: _expandChat,
                onLongPress: _showQuickActions,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _expandChat() {
    setState(() {
      _isChatExpanded = true;
    });
  }

  void _showQuickActions() {
    // Show quick action menu
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Quick Actions',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickActionButton(
              icon: Icons.chat_rounded,
              label: 'Open Chat',
              onTap: () {
                Navigator.pop(context);
                _expandChat();
              },
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              icon: Icons.translate_rounded,
              label: 'Translate Screen',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement translation
              },
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              icon: Icons.security_rounded,
              label: 'Scan for Threats',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement security scan
              },
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              icon: Icons.close_rounded,
              label: 'Close Widget',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _closeOverlay();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? const Color(0xFF00D9FF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
