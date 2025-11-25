import 'package:flutter/services.dart';
import 'dart:async';

class ScreenCaptureService {
  static const MethodChannel _channel =
      MethodChannel('com.example.stremniapp/screen_capture');

  // Singleton pattern
  static final ScreenCaptureService _instance = ScreenCaptureService._internal();
  factory ScreenCaptureService() => _instance;
  ScreenCaptureService._internal() {
    _setupListener();
  }

  // Stream for screen capture results
  final StreamController<ScreenCaptureResult> _resultController =
      StreamController<ScreenCaptureResult>.broadcast();

  Stream<ScreenCaptureResult> get onScreenCaptured => _resultController.stream;

  void _setupListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenCaptured') {
        final Map<dynamic, dynamic> data = call.arguments;
        final result = ScreenCaptureResult(
          text: data['text'] ?? '',
          imageBase64: data['image'],
          success: data['success'] ?? false,
          error: data['error'],
        );
        _resultController.add(result);
      }
    });
  }

  /// Request screen capture permission
  /// Returns true if permission granted
  Future<bool> requestScreenCapturePermission() async {
    try {
      final bool? result = await _channel.invokeMethod('requestScreenCapturePermission');
      return result ?? false;
    } catch (e) {
      print('Error requesting screen capture permission: $e');
      return false;
    }
  }

  /// Capture current screen and extract text using OCR
  Future<ScreenCaptureResult> captureScreen() async {
    try {
      final Map<dynamic, dynamic>? result = 
          await _channel.invokeMethod('captureScreen');
      
      if (result != null) {
        return ScreenCaptureResult(
          text: result['text'] ?? '',
          imageBase64: result['image'],
          success: result['success'] ?? false,
          error: result['error'],
        );
      }
      
      return ScreenCaptureResult(
        text: '',
        success: false,
        error: 'No result returned',
      );
    } catch (e) {
      print('Error capturing screen: $e');
      return ScreenCaptureResult(
        text: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Capture screen text using Accessibility Service
  /// This is faster but requires accessibility permission
  Future<ScreenCaptureResult> captureScreenText() async {
    try {
      final Map<dynamic, dynamic>? result = 
          await _channel.invokeMethod('captureScreenText');
      
      if (result != null) {
        return ScreenCaptureResult(
          text: result['text'] ?? '',
          success: result['success'] ?? false,
          error: result['error'],
        );
      }
      
      return ScreenCaptureResult(
        text: '',
        success: false,
        error: 'No result returned',
      );
    } catch (e) {
      print('Error capturing screen text: $e');
      return ScreenCaptureResult(
        text: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if accessibility service is enabled
  Future<bool> checkAccessibilityPermission() async {
    try {
      final bool? result = await _channel.invokeMethod('checkAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request accessibility permission (opens settings)
  Future<bool> requestAccessibilityPermission() async {
    try {
      final bool? result = await _channel.invokeMethod('requestAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      print('Error requesting accessibility permission: $e');
      return false;
    }
  }

  void dispose() {
    _resultController.close();
  }
}

class ScreenCaptureResult {
  final String text;
  final String? imageBase64;
  final bool success;
  final String? error;

  ScreenCaptureResult({
    required this.text,
    this.imageBase64,
    required this.success,
    this.error,
  });

  @override
  String toString() {
    return 'ScreenCaptureResult(text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., '
        'success: $success, error: $error)';
  }
}
