import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:screenshot/screenshot.dart';
import 'package:stremniapp/services/api_service.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class SystemOverlayScreen extends StatefulWidget {
  const SystemOverlayScreen({Key? key}) : super(key: key);

  @override
  State<SystemOverlayScreen> createState() => _SystemOverlayScreenState();
}

class _SystemOverlayScreenState extends State<SystemOverlayScreen> {
  final ApiService _apiService = ApiService();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  bool _isOverlayActive = false;
  bool _hasPermission = false;
  Map<String, dynamic>? _lastScanResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _setupMessageListener();
  }

  Future<void> _checkPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    setState(() => _hasPermission = status);
  }

  Future<void> _requestPermission() async {
    final bool? status = await FlutterOverlayWindow.requestPermission();
    if (status != null) {
      setState(() => _hasPermission = status);
      if (status) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission granted! You can now enable the floating button.')),
        );
      }
    }
  }

  void _setupMessageListener() {
    FlutterOverlayWindow.overlayListener.listen((data) async {
      if (data == 'analyze_screen') {
        await _analyzeCurrentScreen();
      }
    });
  }

  Future<void> _toggleOverlay() async {
    if (_isOverlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _isOverlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        height: 80,
        width: 80,
        alignment: OverlayAlignment.centerRight,
        enableDrag: true,
      );
      setState(() => _isOverlayActive = true);
    }
  }

  Future<void> _analyzeCurrentScreen() async {
    setState(() => _isAnalyzing = true);
    
    // Notify overlay to show loading
    if (_isOverlayActive) {
      await FlutterOverlayWindow.shareData('analyzing');
    }

    try {
      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Convert to text using OCR or send image directly
      // For now, we'll show a placeholder
      final result = await _apiService.scanContent(
        'Analyzing screenshot content... [OCR integration needed]'
      );

      setState(() {
        _lastScanResult = result;
        _isAnalyzing = false;
      });

      // Notify overlay of result
      if (_isOverlayActive) {
        final isSafe = result['safety']?.toString().toLowerCase().contains('safe') ?? false;
        final isScam = result['safety']?.toString().toLowerCase().contains('scam') ?? false;
        
        if (isScam) {
          await FlutterOverlayWindow.shareData('scam_detected');
        } else {
          await FlutterOverlayWindow.shareData('complete');
        }
      }

      _showResultDialog();
    } catch (e) {
      setState(() => _isAnalyzing = false);
      
      if (_isOverlayActive) {
        await FlutterOverlayWindow.shareData('complete');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showResultDialog() {
    if (_lastScanResult == null) return;

    final status = _lastScanResult!['safety']?.toString() ?? 'Unknown';
    final isScam = status.toLowerCase().contains('scam');
    final isSafe = status.toLowerCase().contains('safe') && !isScam;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isScam ? Icons.dangerous : isSafe ? Icons.check_circle : Icons.warning,
              color: isScam ? Colors.red : isSafe ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(status),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_lastScanResult!['reason'] != null) ...[
              Text(_lastScanResult!['reason']),
              const SizedBox(height: 8),
            ],
            if (_lastScanResult!['details'] != null)
              Text(_lastScanResult!['details'].toString()),
          ],
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

  Color _getStatusColor() {
    if (_lastScanResult == null) return Colors.grey;
    
    final status = _lastScanResult!['safety']?.toString().toLowerCase() ?? '';
    if (status.contains('safe') && !status.contains('unsafe')) {
      return Colors.green;
    } else if (status.contains('scam') || status.contains('unsafe')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Analyzer'),
      ),
      drawer: AppDrawer(),
      body: Screenshot(
        controller: _screenshotController,
        child: SingleChildScrollView(
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
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Overlay Permission',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasPermission
                            ? 'Permission granted. You can enable the floating button.'
                            : 'Grant permission to show floating button over other apps.',
                      ),
                      if (!_hasPermission) ...[
                        const SizedBox(height: 12),
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

              // Floating Button Control Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Floating Security Button',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOverlayActive
                            ? 'Floating button is active. Tap it to analyze any screen!'
                            : 'Enable the floating button to analyze screens system-wide.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasPermission ? _toggleOverlay : null,
                              icon: Icon(_isOverlayActive ? Icons.visibility_off : Icons.visibility),
                              label: Text(_isOverlayActive ? 'Hide Button' : 'Show Button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isOverlayActive ? Colors.orange : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Manual Analysis Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Screen Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to analyze the current screen for scams and suspicious content.',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : _analyzeCurrentScreen,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.screen_search_desktop),
                          label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze This Screen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Last Scan Result
              if (_lastScanResult != null)
                Card(
                  color: _getStatusColor().withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _lastScanResult!['safety']?.toString().toLowerCase().contains('scam') ?? false
                                  ? Icons.dangerous
                                  : Icons.check_circle,
                              color: _getStatusColor(),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lastScanResult!['safety'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                  if (_lastScanResult!['reason'] != null)
                                    Text(_lastScanResult!['reason']),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('How it works', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• Enable the floating button to monitor any screen\n'
                          '• Tap the button to analyze current content\n'
                          '• AI detects scams, phishing, and suspicious content\n'
                          '• Works across all apps system-wide'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
