import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widgets/floating_widget/floating_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFloatingWidgetActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Stremini AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Widget Control Card
            _buildFloatingWidgetCard(),
            
            const SizedBox(height: 24),

            // Features Section
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),

            // Feature Cards Grid
            _buildFeatureCard(
              title: 'AI Chat',
              description: 'Chat with AI anywhere',
              icon: Icons.chat_bubble_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
              ),
              onTap: () => _startFloatingWidget(),
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              title: 'AI Keyboard',
              description: 'Smart text assistance',
              icon: Icons.keyboard_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF5B41FF)],
              ),
              onTap: () {
                // TODO: Open keyboard settings
                _showComingSoonDialog('AI Keyboard');
              },
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              title: 'Screen Translation',
              description: 'Translate any text instantly',
              icon: Icons.translate_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF4B7D)],
              ),
              onTap: () {
                // TODO: Open translation feature
                _showComingSoonDialog('Screen Translation');
              },
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              title: 'Security Scanner',
              description: 'Detect scams and threats',
              icon: Icons.security_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB84D), Color(0xFFFF9B2D)],
              ),
              onTap: () {
                // TODO: Open security scanner
                _showComingSoonDialog('Security Scanner');
              },
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              title: 'Voice Commands',
              description: 'Control with your voice',
              icon: Icons.mic_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
              ),
              onTap: () {
                // TODO: Open voice commands
                _showComingSoonDialog('Voice Commands');
              },
            ),

            const SizedBox(height: 24),

            // About Section
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingWidgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D9FF).withOpacity(0.1),
            const Color(0xFF0099FF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bubble_chart_rounded,
                  color: Color(0xFF00D9FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floating AI Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Access AI from anywhere',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isFloatingWidgetActive 
                  ? _stopFloatingWidget 
                  : _startFloatingWidget,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFloatingWidgetActive 
                    ? Colors.red[600] 
                    : const Color(0xFF00D9FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFloatingWidgetActive 
                        ? Icons.stop_rounded 
                        : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFloatingWidgetActive 
                        ? 'Stop Floating Widget' 
                        : 'Start Floating Widget',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isFloatingWidgetActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Floating widget is active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Stremini AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Powered by Google Gemini 2.5 Flash AI\nVersion 1.0.0',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.security_rounded, 'Secure'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.privacy_tip_rounded, 'Private'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.flash_on_rounded, 'Fast'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00D9FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startFloatingWidget() async {
    try {
      // Check if already running
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        _showSnackBar('Floating widget is already active');
        return;
      }

      // Start the overlay
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        height: 100,
        width: 100,
      );

      setState(() {
        _isFloatingWidgetActive = true;
      });

      _showSnackBar('Floating widget started! 🚀');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _stopFloatingWidget() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      setState(() {
        _isFloatingWidgetActive = false;
      });
      _showSnackBar('Floating widget stopped');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🚧 Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$feature feature is under development and will be available in the next update!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
