import 'package:flutter_overlay_window/flutter_overlay_window.dart';

Future<void> requestOverlayPermissionIfNeeded() async {
  final granted = await FlutterOverlayWindow.isPermissionGranted();
  if (granted == false) {
    await FlutterOverlayWindow.requestPermission();
  }
}
