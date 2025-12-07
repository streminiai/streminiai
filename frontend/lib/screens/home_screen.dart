import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stremini_chatbot/screens/chat_screen.dart';

// Bubble state provider
final bubbleActiveProvider = StateProvider.autoDispose<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const MethodChannel _overlayChannel =
      MethodChannel('stremini.chat.overlay');
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _checkingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;

    setState(() => _checkingPermission = true);
    try {
      final bool? hasOverlay =
          await _overlayChannel.invokeMethod<bool>('hasOverlayPermission');
      final bool? hasAccessibility = await _overlayChannel
          .invokeMethod<bool>('hasAccessibilityPermission');
      setState(() {
        _hasOverlayPermission = hasOverlay ?? false;
        _hasAccessibilityPermission = hasAccessibility ?? false;
        _checkingPermission = false;
      });
    } catch (e) {
      setState(() => _checkingPermission = false);
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _overlayChannel.invokeMethod('requestAccessibilityPermission');
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable "Stremini Screen Scanner" in Accessibility settings',
              style: TextStyle(fontSize: 14),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleBubble(bool value) async {
    if (!_hasOverlayPermission) {
      await _requestOverlayPermission();
      return;
    }

    if (!_hasAccessibilityPermission && value) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Accessibility Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'The Screen Scanner feature requires Accessibility permission to analyze screen content and detect scams.\n\nWould you like to enable it now?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                _requestAccessibilityPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23A6E2),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (result != true) {
        return;
      }
    }

    try {
      if (value) {
        await _overlayChannel.invokeMethod('startOverlayService');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Floating bubble activated! Tap to access features.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _overlayChannel.invokeMethod('stopOverlayService');
      }
      ref.read(bubbleActiveProvider.notifier).state = value;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openQuickChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! 👋';
    } else if (hour < 18) {
      return 'Good afternoon! 👋';
    } else {
      return 'Good evening! 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleActive = ref.watch(bubbleActiveProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/img/logo.jpg',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'Stremini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF23A6E2).withOpacity(0.2),
                    const Color(0xFFAA75F4).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: GestureDetector(
                          onTap: _openQuickChat,
                          child: Row(
                            children: [
                              Icon(Icons.touch_app,
                                  color: Colors.blue[300], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Quick Chat',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered scam protection is ready',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // AI Features Title
            const Text(
              'AI Features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Smart Chatbot Card
            _buildFeatureCard(
              title: 'Smart Chatbot & Scam Detector',
              description:
                  'Floating AI assistant with intelligent screen analyzer. Works system-wide across all apps!',
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFF23A6E2),
              status: bubbleActive ? 'Active' : 'Inactive',
              statusColor: bubbleActive ? Colors.green : Colors.grey,
              badges: const [
                'Floating Chat',
                'Screen Scanner',
                'Scam Detection',
                'System-Wide'
              ],
              trailing: Switch(
                value: bubbleActive,
                onChanged: _toggleBubble,
                activeColor: const Color(0xFF23A6E2),
              ),
              onTap: null,
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF00D9FF), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'How to use:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoStep(
                      '1', 'Tap the floating bubble to open radial menu'),
                  _buildInfoStep('2', 'Select Chat icon to start conversation'),
                  _buildInfoStep(
                      '3', 'Select Scanner icon to analyze screen for scams'),
                  _buildInfoStep(
                      '4', 'AI will show tags near suspicious content (Scam, Safe, Tone, etc.)'),
                  _buildInfoStep('5', 'Tap tags to see why content is flagged'),
                  _buildInfoStep('6', 'Tap scanner again to hide all tags'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Permission Status
            if (!_hasOverlayPermission || !_hasAccessibilityPermission) ...[
              const Text(
                'Required Permissions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (!_hasOverlayPermission)
                _buildPermissionCard(
                  'Overlay Permission',
                  'Required for floating bubble over other apps',
                  Icons.bubble_chart,
                  Colors.orange,
                  _requestOverlayPermission,
                ),
              if (!_hasAccessibilityPermission)
                _buildPermissionCard(
                  'Accessibility Permission',
                  'Required for screen scanner to read screen content and detect scams',
                  Icons.accessibility_new,
                  Colors.purple,
                  _requestAccessibilityPermission,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D9FF)),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF272727),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search for features',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.white24),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildDrawerItem(Icons.home, 'Home', () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.settings, 'Settings', () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.help_outline, 'Contact Us', () {
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String status,
    required Color statusColor,
    required List<String> badges,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((badge) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: color.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Enable',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
