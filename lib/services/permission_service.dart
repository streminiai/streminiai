import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check if all required permissions are granted
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'internet': true, // Internet is always granted
      'camera': await Permission.camera.isGranted,
      'storage': await _checkStoragePermission(),
      'overlay': await Permission.systemAlertWindow.isGranted,
    };
  }

  // Check storage permission (varies by Android version)
  static Future<bool> _checkStoragePermission() async {
    if (await Permission.photos.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request storage/photos permission
  static Future<bool> requestStoragePermission() async {
    // Try photos first (Android 13+)
    var status = await Permission.photos.request();
    if (status.isGranted) return true;

    // Fallback to storage (older Android)
    status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request overlay permission (for floating button)
  static Future<bool> requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  // Request all permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    // Camera
    results['camera'] = await requestCameraPermission();
    
    // Storage
    results['storage'] = await requestStoragePermission();
    
    // Overlay
    results['overlay'] = await requestOverlayPermission();
    
    results['internet'] = true; // Always true
    
    return results;
  }

  // Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Show permission dialog
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function() onRequest,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final granted = await onRequest();
              if (context.mounted) {
                Navigator.pop(context, granted);
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Check and request permission with explanation
  static Future<bool> ensurePermission(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String message,
  }) async {
    // Check if already granted
    if (await permission.isGranted) return true;

    // Check if we should show rationale
    if (await permission.shouldShowRequestRationale) {
      // Show explanation dialog
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) return false;
    }

    // Request permission
    final status = await permission.request();
    
    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied && context.mounted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text('$title permission is required. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await PermissionService.openAppSettings();
      }
    }

    return status.isGranted;
  }
}

// Permission status widget
class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({Key? key}) : super(key: key);

  @override
  State<PermissionStatusWidget> createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final perms = await PermissionService.checkAllPermissions();
    setState(() {
      _permissions = perms;
      _isLoading = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);
    final perms = await PermissionService.requestAllPermissions();
    setState(() {
      _permissions = perms;
      _isLoading = false;
    });

    if (_permissions.values.every((granted) => granted)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All permissions granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildPermissionRow(
              'Internet',
              _permissions['internet'] ?? false,
              Icons.wifi,
              'Required for AI chat',
            ),
            _buildPermissionRow(
              'Camera',
              _permissions['camera'] ?? false,
              Icons.camera_alt,
              'For image analysis',
            ),
            _buildPermissionRow(
              'Storage',
              _permissions['storage'] ?? false,
              Icons.folder,
              'To save and load images',
            ),
            _buildPermissionRow(
              'Overlay',
              _permissions['overlay'] ?? false,
              Icons.layers,
              'For floating security button',
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestAllPermissions,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Grant All Permissions'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(
    String name,
    bool granted,
    IconData icon,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: granted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
