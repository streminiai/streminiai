import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_drawer.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    
    final statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.systemAlertWindow,
    ].request();

    setState(() {
      _permissionStatuses = statuses;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission, String name) async {
    final status = await permission.request();
    
    setState(() {
      _permissionStatuses[permission] = status;
    });

    if (status.isGranted) {
      _showSnackBar('✅ $name permission granted', Colors.green);
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(name);
    } else {
      _showSnackBar('❌ $name permission denied', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionName permission is required for this feature. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // App Info Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Stremini AI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Version 1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Permissions Section
                Text(
                  'Permissions',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage app permissions for optimal functionality',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Internet Permission (Always Granted)
                _buildPermissionCard(
                  icon: Icons.wifi,
                  title: 'Internet Access',
                  description: 'Required for AI chat and analysis',
                  status: PermissionStatus.granted,
                  onTap: null, // Cannot be changed
                ),

                // Camera Permission
                _buildPermissionCard(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  description: 'Take photos for content analysis',
                  status: _permissionStatuses[Permission.camera],
                  onTap: () => _requestPermission(Permission.camera, 'Camera'),
                ),

                // Storage/Photos Permission
                _buildPermissionCard(
                  icon: Icons.photo_library,
                  title: 'Photos & Media',
                  description: 'Access gallery images for analysis',
                  status: _permissionStatuses[Permission.photos] ??
                      _permissionStatuses[Permission.storage],
                  onTap: () => _requestPermission(
                    Permission.photos,
                    'Photos & Media',
                  ),
                ),

                // Overlay Permission
                _buildPermissionCard(
                  icon: Icons.layers,
                  title: 'Display Over Other Apps',
                  description: 'Show floating security button',
                  status: _permissionStatuses[Permission.systemAlertWindow],
                  onTap: () => _requestPermission(
                    Permission.systemAlertWindow,
                    'Overlay',
                  ),
                ),

                const SizedBox(height: 24),

                // Grant All Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _requestAllPermissions,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Grant All Permissions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Open System Settings Button
                OutlinedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open System Settings'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 32),

                // About Section
                Text(
                  'About',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Stremini AI'),
                  onTap: () => _showAboutDialog(),
                ),

                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    _showSnackBar('Privacy policy coming soon', Colors.blue);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  onTap: () {
                    _showSnackBar('Terms of service coming soon', Colors.blue);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus? status,
    required VoidCallback? onTap,
  }) {
    final isGranted = status?.isGranted ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    String statusText = 'Unknown';

    if (isGranted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Granted';
    } else if (isPermanentlyDenied) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Denied';
    } else if (status != null) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Not Granted';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: statusColor, size: 28),
        title: Text(title),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 10, color: statusColor),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    await _requestPermission(Permission.camera, 'Camera');
    await _requestPermission(Permission.photos, 'Photos');
    await _requestPermission(Permission.systemAlertWindow, 'Overlay');

    await _loadPermissions();

    if (_permissionStatuses.values.every((status) => status.isGranted)) {
      _showSnackBar('✅ All permissions granted!', Colors.green);
    } else {
      _showSnackBar('⚠️ Some permissions not granted', Colors.orange);
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Stremini AI',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.security, color: Colors.white, size: 32),
      ),
      children: [
        const SizedBox(height: 16),
        const Text('Your intelligent digital bodyguard powered by AI.'),
        const SizedBox(height: 8),
        const Text('Protect yourself from scams, phishing, and online threats.'),
        const SizedBox(height: 16),
        const Text(
          'Developed by Stremini AI Developers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
