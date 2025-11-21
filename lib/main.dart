import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/theme/app_theme.dart';

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
  runApp(const StreminiChatbot());
}

class StreminiChatbot extends StatelessWidget {
  const StreminiChatbot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stremini Chatbot',
      theme: AppTheme.darkTheme,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Enhanced Overlay Widget matching the design
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _isExpanded = false;
  String _currentStatus = 'idle'; // idle, analyzing, safe, danger
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for button press effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen for messages from main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'analyzing') {
        setState(() {
          _isAnalyzing = true;
          _currentStatus = 'analyzing';
        });
      } else if (data == 'complete') {
        setState(() {
          _isAnalyzing = false;
          _currentStatus = 'safe';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _currentStatus = 'idle');
        });
      } else if (data == 'scam_detected') {
        setState(() {
          _isAnalyzing = false;
          _currentStatus = 'danger';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _currentStatus = 'idle');
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getMainButtonColor() {
    switch (_currentStatus) {
      case 'analyzing':
        return const Color(0xFF3B82F6); // Blue
      case 'safe':
        return const Color(0xFF10B981); // Green
      case 'danger':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF3B82F6); // Default Blue
    }
  }

  void _handleMainButtonTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Send message to main app to trigger analysis
    FlutterOverlayWindow.shareData('analyze_screen');
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay to close menu (shown when expanded)
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isExpanded = false),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),

          // Expanded menu buttons (shown when expanded)
          if (_isExpanded) ...[
            // Top button - Quick Info
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 - 110,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildSecondaryButton(
                  icon: Icons.info_outline,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    FlutterOverlayWindow.shareData('show_info');
                  },
                ),
              ),
            ),

            // Bottom button - Settings
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 + 50,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildSecondaryButton(
                  icon: Icons.settings,
                  color: const Color(0xFF6B7280),
                  onTap: () {
                    FlutterOverlayWindow.shareData('open_settings');
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 + 130,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildSecondaryButton(
                  icon: Icons.close,
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    FlutterOverlayWindow.closeOverlay();
                  },
                ),
              ),
            ),
          ],

          // Main floating button (always visible)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 30,
            child: GestureDetector(
              onTap: _handleMainButtonTap,
              onLongPress: _toggleExpansion,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getMainButtonColor(),
                        _getMainButtonColor().withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getMainButtonColor().withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isAnalyzing
                      ? const Padding(
                          padding: EdgeInsets.all(15),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          _getIconForStatus(),
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ),
          ),

          // Status indicator (small dot)
          if (_currentStatus != 'idle')
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 26,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _currentStatus == 'safe' 
                      ? Colors.green 
                      : _currentStatus == 'danger'
                          ? Colors.red
                          : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() => _isExpanded = false);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  IconData _getIconForStatus() {
    switch (_currentStatus) {
      case 'safe':
        return Icons.check_circle;
      case 'danger':
        return Icons.warning;
      case 'analyzing':
        return Icons.security;
      default:
        return Icons.shield;
    }
  }
}
