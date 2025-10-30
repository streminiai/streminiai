import 'dart:developer' as dev;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayController {
  static Future<bool> ensurePermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted == true) return true;
    final ok = await FlutterOverlayWindow.requestPermission();
    return ok == true;
  }

  static Future<bool> showBubble() async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) {
        dev.log('Overlay permission denied', name: 'overlay');
        return false;
      }
      final active = await FlutterOverlayWindow.isActive();
      if (active == true) return true;
      final result = await FlutterOverlayWindow.showOverlay(
        entryPoint: 'overlayMain',
        height: 100,
        width: 100,
        enableDrag: true,
        alignment: OverlayAlignment.centerRight,
        overlayTitle: 'Stremini Chat',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );
      dev.log('showOverlay result: $result', name: 'overlay');
      return true;
    } catch (e) {
      dev.log('Failed to show overlay: $e', name: 'overlay', error: e);
      return false;
    }
  }

  static Future<void> closeBubble() async {
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active == true) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      dev.log('Failed to close overlay: $e', name: 'overlay', error: e);
    }
  }
}
