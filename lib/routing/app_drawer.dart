import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.security, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Stremini AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your Digital Bodyguard',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Main Features
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              title: 'Home',
              route: AppRouter.home,
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'AI Chat',
              route: AppRouter.chat,
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.document_scanner_outlined,
              title: 'Content Analyzer',
              route: AppRouter.analyzer,
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.shield_outlined,
              title: 'Screen Analyzer',
              route: AppRouter.systemOverlay,
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.keyboard_alt_outlined,
              title: 'Custom Keyboard',
              route: AppRouter.keyboard,
              currentRoute: currentRoute,
            ),
            
            const Divider(),
            
            // Additional Features
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History feature coming soon!')),
                );
              },
            ),
            
            // Settings - NOW FUNCTIONAL
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              route: AppRouter.settings,
              currentRoute: currentRoute,
            ),
            
            const Divider(),
            
            // About
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
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
                    const Text('Developed by Stremini AI Developers'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required String? currentRoute,
  }) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
