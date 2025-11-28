import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'chat_screen.dart';

// Bubble state provider
final bubbleActiveProvider = StateProvider.autoDispose<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const MethodChannel _overlayChannel = MethodChannel('stremini.chat.overlay');
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _checkingPermission = false;
  int _threatsBlocked = 24;
  int _protectionRate = 99;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;
    
    setState(() => _checkingPermission = true);
    try {
      final bool? hasOverlay = await _overlayChannel.invokeMethod<bool>('hasOverlayPermission');
      final bool? hasAccessibility = await _overlayChannel.invokeMethod<bool>('hasAccessibilityPermission');
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

    try {
      if (value) {
        await _overlayChannel.invokeMethod('startOverlayService');
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
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [Color(0xFF23A6E2), Color(0xFFAA75F4), Color(0xFF0066FF)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.shield, color: Colors.white, size: 18),
              ),
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
                      const Text(
                        'Good afternoon! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.blue[300], size: 16),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI assistant is ready',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    value: '$_threatsBlocked',
                    label: 'Threats\nBlocked',
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF23A6E2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    value: 'AI',
                    label: 'Always\nActive',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFFAA75F4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    value: '$_protectionRate%',
                    label: 'Protection\nRate',
                    icon: Icons.verified_user,
                    color: const Color(0xFF0066FF),
                  ),
                ),
              ],
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

            // Smart Chatbot Card - Controls Native Bubble
            _buildFeatureCard(
              title: 'Smart Chatbot',
              description: 'Floating AI assistant with chat & screen analyzer. Works over all apps!',
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFF23A6E2),
              status: bubbleActive ? 'Active' : 'Inactive',
              statusColor: bubbleActive ? Colors.green : Colors.grey,
              badges: const ['Floating Chat', 'Screen Scanner', 'System-Wide'],
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
                border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00D9FF), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'When enabled, a floating bubble appears. Tap it to access Chat and Screen Scanner features over any app!',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Permission Status
            if (!_hasOverlayPermission || !_hasAccessibilityPermission) ...[
              const Text(
                'Permissions',
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
                  'Required for screen scanner to read screen content',
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              
              // Menu Items
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

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Enable',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
