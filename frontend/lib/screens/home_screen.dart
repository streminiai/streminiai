import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/services.dart';

// Bubble state provider
final bubbleActiveProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const MethodChannel _overlayChannel = MethodChannel('stremini.chat.overlay');
  bool _hasOverlayPermission = false;
  bool _checkingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
  }

  Future<void> _checkOverlayPermission() async {
    if (!Platform.isAndroid) return;
    
    setState(() => _checkingPermission = true);
    try {
      final bool? has = await _overlayChannel.invokeMethod<bool>('hasOverlayPermission');
      setState(() {
        _hasOverlayPermission = has ?? false;
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
      // Wait a bit and check again
      await Future.delayed(const Duration(seconds: 1));
      await _checkOverlayPermission();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleBubble(bool value) async {
    if (!_hasOverlayPermission) {
      await _requestOverlayPermission();
      return;
    }

    try {
      if (value) {
        await _overlayChannel.invokeMethod('startOverlayService');
      } else {
        await _overlayChannel.invokeMethod('stopOverlayService');
      }
      ref.read(bubbleActiveProvider.notifier).state = value;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleActive = ref.watch(bubbleActiveProvider);
    final scannerState = ref.watch(scannerStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [Color(0xFF23A6E2), Color(0xFFAA75F4), Color(0xFF0066FF)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Stremini AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF23A6E2).withOpacity(0.2),
                    const Color(0xFFAA75F4).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Stremini AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your intelligent assistant for chat, security, and screen analysis',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Floating Bubble Control
            _buildFeatureCard(
              title: 'Floating AI Bubble',
              description: 'Access AI assistant from anywhere',
              icon: Icons.bubble_chart,
              iconColor: const Color(0xFF23A6E2),
              trailing: Switch(
                value: bubbleActive,
                onChanged: _toggleBubble,
                activeColor: const Color(0xFF23A6E2),
              ),
              onTap: () {
                if (!_hasOverlayPermission) {
                  _requestOverlayPermission();
                }
              },
            ),

            const SizedBox(height: 16),

            // Screen Scanner Control
            _buildFeatureCard(
              title: 'Screen Scanner',
              description: 'Detect scams and analyze content',
              icon: Icons.security,
              iconColor: const Color(0xFFAA75F4),
              trailing: Switch(
                value: scannerState.isActive,
                onChanged: (value) async {
                  if (!scannerState.hasPermission) {
                    await ref.read(scannerStateProvider.notifier).requestPermission();
                  } else {
                    await ref.read(scannerStateProvider.notifier).toggleScanning();
                  }
                },
                activeColor: const Color(0xFFAA75F4),
              ),
              badge: !scannerState.hasPermission
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Permission Required',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 32),

            // Features Section
            const Text(
              'Features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),

            _buildSmallFeatureCard(
              title: 'AI Chat',
              description: 'Intelligent conversation',
              icon: Icons.chat,
              color: const Color(0xFF23A6E2),
              onTap: () {
                // Navigate to chat screen
              },
            ),

            const SizedBox(height: 12),

            _buildSmallFeatureCard(
              title: 'Text Analysis',
              description: 'Analyze tone & emotion',
              icon: Icons.analytics,
              color: const Color(0xFFAA75F4),
              onTap: () {
                // Open text analysis
              },
            ),

            const SizedBox(height: 12),

            _buildSmallFeatureCard(
              title: 'Voice Commands',
              description: 'Control with your voice',
              icon: Icons.mic,
              color: const Color(0xFF0066FF),
              onTap: () {
                // Open voice commands
              },
            ),

            const SizedBox(height: 32),

            // Status Info
            if (_checkingPermission)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            else if (!_hasOverlayPermission && Platform.isAndroid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overlay Permission Required',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable to use floating bubble',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _requestOverlayPermission,
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    Widget? badge,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ],
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
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
