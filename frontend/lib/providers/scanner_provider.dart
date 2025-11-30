import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ScreenScannerController {
  static const MethodChannel _channel = MethodChannel('stremini.screen.scanner');

  Future<bool> hasAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? has = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
      return has ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      print('Error requesting accessibility permission: $e');
    }
  }

  Future<bool> startScanning() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod('startScanning');
      return result == true;
    } catch (e) {
      print('Error starting scan: $e');
      return false;
    }
  }

  Future<void> stopScanning() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopScanning');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<bool> isScanning() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? scanning = await _channel.invokeMethod<bool>('isScanning');
      return scanning ?? false;
    } catch (e) {
      return false;
    }
  }
}

// State for scanner
class ScannerState {
  final bool isActive;
  final bool hasPermission;
  final String? error;

  ScannerState({
    this.isActive = false,
    this.hasPermission = false,
    this.error,
  });

  ScannerState copyWith({
    bool? isActive,
    bool? hasPermission,
    String? error,
  }) {
    return ScannerState(
      isActive: isActive ?? this.isActive,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error,
    );
  }
}

class ScannerStateNotifier extends StateNotifier<ScannerState> {
  final ScreenScannerController _controller;

  ScannerStateNotifier(this._controller) : super(ScannerState()) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _controller.hasAccessibilityPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  Future<void> requestPermission() async {
    await _controller.requestAccessibilityPermission();
    // Check again after a delay
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermission();
  }

  Future<void> toggleScanning() async {
    if (state.isActive) {
      await stopScanning();
    } else {
      await startScanning();
    }
  }

  Future<void> startScanning() async {
    if (!state.hasPermission) {
      state = state.copyWith(error: 'Accessibility permission required');
      await requestPermission();
      return;
    }

    final success = await _controller.startScanning();
    if (success) {
      state = state.copyWith(isActive: true, error: null);
    } else {
      state = state.copyWith(error: 'Failed to start scanning');
    }
  }

  Future<void> stopScanning() async {
    await _controller.stopScanning();
    state = state.copyWith(isActive: false);
  }

  Future<void> checkScanningStatus() async {
    final isScanning = await _controller.isScanning();
    state = state.copyWith(isActive: isScanning);
  }
}

// Providers
final screenScannerControllerProvider = Provider<ScreenScannerController>(
  (ref) => ScreenScannerController(),
);

final scannerStateProvider = StateNotifierProvider<ScannerStateNotifier, ScannerState>(
  (ref) => ScannerStateNotifier(ref.watch(screenScannerControllerProvider)),
);
