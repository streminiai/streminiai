import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class SystemOverlayScreen extends StatefulWidget {
  const SystemOverlayScreen({Key? key}) : super(key: key);

  @override
  State<SystemOverlayScreen> createState() => _SystemOverlayScreenState();
}

class _SystemOverlayScreenState extends State<SystemOverlayScreen> {
  bool _hasPermission = false;
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _checkOverlayStatus();
  }

  Future<void> _checkPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    setState(() => _hasPermission = status);
  }

  Future<void> _checkOverlayStatus() async {
    final active = await FlutterOverlayWindow.isActive();
    setState(() => _isOverlayActive = active);
  }

  Future<void> _requestPermission() async {
    final result = await FlutterOverlayWindow.requestPermission();
    if (result == true) {
      setState(() => _hasPermission = true);
      _showSnack('Permission granted!', Colors.green);
    }
  }

  Future<void> _toggleOverlay() async {
    if (_isOverlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _isOverlayActive = false);
      _showSnack('Bubble hidden', Colors.orange);
    } else {
      await FlutterOverlayWindow.showOverlay(
        height: 150,
        width: 150,
        alignment: OverlayAlignment.centerRight,
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        overlayTitle: "Stremini AI",
        overlayContent: "Protection active",
      );
      setState(() => _isOverlayActive = true);
      _showSnack('Bubble activated! You can now close the app.', Colors.green);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Floating Bubble')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasPermission ? Icons.check_circle : Icons.warning,
                          color: _hasPermission ? Colors.green : Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Overlay Permission',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasPermission
                          ? 'Permission granted. You can enable the floating bubble.'
                          : 'Grant permission to show floating bubble over other apps.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (!_hasPermission) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _requestPermission,
                        icon: const Icon(Icons.security),
                        label: const Text('Grant Permission'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bubble Control Card
            Card(
              color: _isOverlayActive
                  ? Colors.green.withOpacity(0.1)
                  : theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isOverlayActive
                                  ? [const Color(0xFF00F0FF), const Color(0xFF0080FF)]
                                  : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isOverlayActive ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Floating Bubble',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                _isOverlayActive
                                    ? 'Active - Tap bubble to access features'
                                    : 'Inactive',
                                style: TextStyle(
                                  color: _isOverlayActive ? Colors.green : theme.disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _hasPermission ? _toggleOverlay : null,
                        icon: Icon(_isOverlayActive ? Icons.visibility_off : Icons.visibility),
                        label: Text(_isOverlayActive ? 'Hide Bubble' : 'Show Bubble'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOverlayActive ? Colors.orange : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions Card
            Card(
              color: theme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'How It Works',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Tap "Show Bubble" to activate the floating button'),
                    _buildStep('2', 'The bubble stays on screen even after closing the app'),
                    _buildStep('3', 'Tap the bubble to access AI Chatbot or Scan Screen'),
                    _buildStep('4', 'Features turn blue when active'),
                    _buildStep('5', 'Tap again to deactivate, or use "Close Bubble"'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Features Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bubble Features',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      Icons.chat_bubble,
                      'AI Chatbot',
                      'Opens floating chat window',
                      const Color(0xFF00F0FF),
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(
                      Icons.screen_search_desktop,
                      'Scan Screen',
                      'Analyzes screen for scams & threats',
                      const Color(0xFF00F0FF),
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(
                      Icons.close,
                      'Close Bubble',
                      'Removes floating button',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
