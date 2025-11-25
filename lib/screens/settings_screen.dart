import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_drawer.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);

    final statuses = <Permission, PermissionStatus>{};

    statuses[Permission.camera] = await Permission.camera.status;
    statuses[Permission.photos] = await Permission.photos.status;
    statuses[Permission.systemAlertWindow] = await Permission.systemAlertWindow.status;

    setState(() {
      _statuses = statuses;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission perm, String name) async {
    final status = await perm.request();

    setState(() => _statuses[perm] = status);

    if (status.isGranted) {
      _showSnack('$name permission granted', Colors.green);
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(name);
    } else {
      _showSnack('$name permission denied', Colors.red);
    }
  }

  Future<void> _requestAll() async {
    setState(() => _isLoading = true);

    await _requestPermission(Permission.camera, 'Camera');
    await _requestPermission(Permission.photos, 'Photos');
    await _requestPermission(Permission.systemAlertWindow, 'Overlay');

    await _loadPermissions();

    final allGranted = _statuses.values.every((s) => s.isGranted);
    _showSnack(
      allGranted ? 'All permissions granted!' : 'Some permissions not granted',
      allGranted ? Colors.green : Colors.orange,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showSettingsDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text('$name permission was denied. Enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // App Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.security, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stremini AI',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Permissions Section
                Text('Permissions', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Manage app permissions for full functionality',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                _buildPermissionTile(
                  icon: Icons.wifi,
                  title: 'Internet',
                  desc: 'Required for AI features',
                  status: PermissionStatus.granted,
                  onTap: null,
                ),

                _buildPermissionTile(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  desc: 'Take photos for analysis',
                  status: _statuses[Permission.camera],
                  onTap: () => _requestPermission(Permission.camera, 'Camera'),
                ),

                _buildPermissionTile(
                  icon: Icons.photo_library,
                  title: 'Photos',
                  desc: 'Access images for analysis',
                  status: _statuses[Permission.photos],
                  onTap: () => _requestPermission(Permission.photos, 'Photos'),
                ),

                _buildPermissionTile(
                  icon: Icons.layers,
                  title: 'Display Over Apps',
                  desc: 'Show floating bubble',
                  status: _statuses[Permission.systemAlertWindow],
                  onTap: () => _requestPermission(Permission.systemAlertWindow, 'Overlay'),
                ),

                const SizedBox(height: 24),

                // Grant All
                ElevatedButton.icon(
                  onPressed: _requestAll,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Grant All Permissions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open System Settings'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 32),

                // About Section
                Text('About', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Stremini AI'),
                  onTap: () => _showAbout(),
                ),

                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () => _showSnack('Coming soon', Colors.blue),
                ),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  onTap: () => _showSnack('Coming soon', Colors.blue),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String desc,
    required PermissionStatus? status,
    required VoidCallback? onTap,
  }) {
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isPermanentlyDenied ?? false;

    Color color = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    String statusText = 'Unknown';

    if (isGranted) {
      color = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Granted';
    } else if (isDenied) {
      color = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Denied';
    } else if (status != null) {
      color = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Not Granted';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color, size: 26),
        title: Text(title),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: color, size: 18),
                Text(statusText, style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAbout() {
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
      children: const [
        SizedBox(height: 16),
        Text('Your intelligent digital bodyguard powered by AI.'),
        SizedBox(height: 8),
        Text('Protect yourself from scams, phishing, and online threats.'),
      ],
    );
  }
}
