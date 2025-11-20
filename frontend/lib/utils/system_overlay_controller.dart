import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add Riverpod import
import 'package:stremini_chatbot/providers/chat_window_state_provider.dart';


class SystemOverlayController extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const SystemOverlayController(
      {super.key, required this.child, required this.navigatorKey});

  @override
  ConsumerState<SystemOverlayController> createState() =>
      _SystemOverlayControllerState();
}

class _SystemOverlayControllerState
    extends ConsumerState<SystemOverlayController> with WidgetsBindingObserver {
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
    if (!Platform.isAndroid) return true;
    try {
      final bool? has =
          await _channel.invokeMethod<bool>('hasOverlayPermission');
      return has ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _promptIfNoPermission() async {
    if (!Platform.isAndroid) return;
    final has = await _hasPermission();
    final navContext = widget.navigatorKey.currentContext;

    if (!has && mounted && !_promptedOnce && navContext != null) {
      _promptedOnce = true;

      showDialog(
        context: navContext,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Floating Chat'),
          content: const Text(
              'To see the chat bubble over other apps, please allow "Display over other apps".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await _channel.invokeMethod('requestOverlayPermission');
                } catch (_) {}
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!Platform.isAndroid) return;
    final notifier = ref.read(chatWindowStateProvider.notifier);

    try {
      if (state == AppLifecycleState.paused) {
        // App goes to background -> Start Native Service
        final has = await _hasPermission();
        if (has) {
          // Set state to 'icon' before entering background
          notifier.setMode("icon");
          await _channel.invokeMethod('startOverlayService');
        }
      } else if (state == AppLifecycleState.resumed) {
        // App comes to foreground -> Stop Native Service
        await _channel.invokeMethod('stopOverlayService');

        // 🚨 CRITICAL FIX: Force the mode to 'radial' when resuming
        // This makes the radial menu appear instantly upon returning from the background.
        notifier.setMode("radial");
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
