import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stremniapp/services/screen_capture_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScreenCaptureService _captureService = ScreenCaptureService();
  
  bool _isOverlayActive = false;
  bool _hasOverlayPermission = false;
  bool _hasScreenCapturePermission = false;
  
  late AnimationController _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowAnim = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _checkPermissions();
    _checkOverlayStatus();
  }

  @override
  void dispose() {
    _glowAnim.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final overlayStatus = await Permission.systemAlertWindow.status;
    setState(() {
      _hasOverlayPermission = overlayStatus.isGranted;
    });
  }

  Future<void> _checkOverlayStatus() async {
    final status = await FlutterOverlayWindow.isActive();
    setState(() => _isOverlayActive = status);
  }

  Future<void> _requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    setState(() {
      _hasOverlayPermission = status.isGranted;
    });
    
    if (!status.isGranted) {
      _showPermissionDialog();
    }
  }

  Future<void> _requestScreenCapturePermission() async {
    final granted = await _captureService.requestScreenCapturePermission();
    setState(() {
      _hasScreenCapturePermission = granted;
    });
    
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Screen capture permission granted'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF00F0FF)),
            SizedBox(width: 12),
            Text('Permission Required', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Stremini AI needs overlay permission to show the floating bubble. '
          'This allows real-time scam detection while you use other apps.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _requestOverlayPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Future<void> _startOverlay() async {
    if (!_hasOverlayPermission) {
      await _requestOverlayPermission();
      return;
    }

    try {
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.fullScreen,
        width: WindowSize.fullScreen,
        enableDrag: false,
      );
      
      setState(() => _isOverlayActive = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ Stremini AI is now protecting you'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    setState(() => _isOverlayActive = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Logo & Title
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (ctx, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF0080FF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withOpacity(0.3 + _glowAnim.value * 0.3),
                          blurRadius: 30 + _glowAnim.value * 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Stremini AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Your Digital Bodyguard',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOverlayActive 
                        ? const Color(0xFF00F0FF).withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isOverlayActive 
                                ? const Color(0xFF10B981) 
                                : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: _isOverlayActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isOverlayActive ? 'Protection Active' : 'Protection Inactive',
                          style: TextStyle(
                            color: _isOverlayActive 
                                ? const Color(0xFF10B981) 
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      _isOverlayActive
                          ? 'Floating bubble is monitoring your screen for scams'
                          : 'Start protection to enable real-time scam detection',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOverlayActive ? _stopOverlay : _startOverlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOverlayActive 
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF00F0FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOverlayActive ? Icons.stop_circle : Icons.shield,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isOverlayActive ? 'Stop Protection' : 'Start Protection',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Permission Cards
              _buildPermissionCard(
                title: 'Overlay Permission',
                description: 'Required for floating bubble',
                icon: Icons.layers,
                granted: _hasOverlayPermission,
                onRequest: _requestOverlayPermission,
              ),
              
              const SizedBox(height: 16),
              
              _buildPermissionCard(
                title: 'Screen Capture',
                description: 'Required to scan screen content',
                icon: Icons.screenshot,
                granted: _hasScreenCapturePermission,
                onRequest: _requestScreenCapturePermission,
              ),
              
              const SizedBox(height: 32),
              
              // Features
              const Text(
                'Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                icon: Icons.chat_bubble_rounded,
                title: 'AI Chatbot',
                description: 'Ask questions about suspicious content',
                color: const Color(0xFF00F0FF),
              ),
              
              const SizedBox(height: 12),
              
              _buildFeatureCard(
                icon: Icons.screen_search_desktop_rounded,
                title: 'Screen Scanner',
                description: 'Detect scams, phishing, and threats in real-time',
                color: const Color(0xFF8B5CF6),
              ),
              
              const SizedBox(height: 12),
              
              _buildFeatureCard(
                icon: Icons.security_rounded,
                title: 'Real-time Protection',
                description: 'Always-on security monitoring',
                color: const Color(0xFF10B981),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool granted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: granted 
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: granted ? const Color(0xFF10B981) : Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            const Icon(Icons.check_circle, color: Color(0xFF10B981))
          else
            TextButton(
              onPressed: onRequest,
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
