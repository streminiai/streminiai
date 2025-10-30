import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemOverlayController extends StatefulWidget {
  final Widget child;
  const SystemOverlayController({super.key, required this.child});

  @override
  State<SystemOverlayController> createState() => _SystemOverlayControllerState();
}

class _SystemOverlayControllerState extends State<SystemOverlayController> with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('stremini.chat.overlay');
  bool _promptedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptIfNoPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _hasPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final has = await _channel.invokeMethod<bool>('hasOverlayPermission') ?? true;
      return has;
    } catch (_) {
      return false;
    }
  }

  Future<void> _promptIfNoPermission() async {
    if (!Platform.isAndroid) return;
    final has = await _hasPermission();
    if (!has && mounted && !_promptedOnce) {
      _promptedOnce = true;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow “Draw over other apps”'),
            content: const Text('To show the floating chat bubble when minimized, enable the overlay permission.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try { await _channel.invokeMethod('requestOverlayPermission'); } catch (_) {}
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!Platform.isAndroid) return;
    try {
      if (state == AppLifecycleState.paused) {
        final has = await _hasPermission();
        if (has) {
          await _channel.invokeMethod('startOverlayService');
        } else {
          await _channel.invokeMethod('requestOverlayPermission');
        }
      } else if (state == AppLifecycleState.resumed) {
        await _channel.invokeMethod('stopOverlayService');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


