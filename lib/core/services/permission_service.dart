import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final StorageService _storage = StorageService();

  // Check and request overlay permission (for floating button)
  Future<bool> requestOverlayPermission() async {
    if (await Permission.systemAlertWindow.isGranted) {
      await _storage.savePermissionStatus('overlay', true);
      return true;
    }

    final status = await Permission.systemAlertWindow.request();
    final granted = status.isGranted;
    await _storage.savePermissionStatus('overlay', granted);
    return granted;
  }

  Future<bool> hasOverlayPermission() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  // Check and request microphone permission (for voice commands)
  Future<bool> requestMicrophonePermission() async {
    if (await Permission.microphone.isGranted) {
      await _storage.savePermissionStatus('microphone', true);
      return true;
    }

    final status = await Permission.microphone.request();
    final granted = status.isGranted;
    await _storage.savePermissionStatus('microphone', granted);
    return granted;
  }

  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  // Check and request storage permission
  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      await _storage.savePermissionStatus('storage', true);
      return true;
    }

    final status = await Permission.storage.request();
    final granted = status.isGranted;
    await _storage.savePermissionStatus('storage', granted);
    return granted;
  }

  // Check and request notification permission
  Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      await _storage.savePermissionStatus('notification', true);
      return true;
    }

    final status = await Permission.notification.request();
    final granted = status.isGranted;
    await _storage.savePermissionStatus('notification', granted);
    return granted;
  }

  // Request all necessary permissions at once
  Future<Map<String, bool>> requestAllPermissions() async {
    return {
      'overlay': await requestOverlayPermission(),
      'microphone': await requestMicrophonePermission(),
      'storage': await requestStoragePermission(),
      'notification': await requestNotificationPermission(),
    };
  }

  // Check if all critical permissions are granted
  Future<bool> hasAllCriticalPermissions() async {
    final overlay = await hasOverlayPermission();
    final microphone = await hasMicrophonePermission();
    return overlay && microphone;
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
