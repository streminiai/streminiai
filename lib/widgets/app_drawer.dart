
import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 80), // Spacer for status bar and header
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              title: 'Home',
              route: AppRouter.home,
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.add_comment_outlined,
              title: 'New Chat',
              route: AppRouter.analyzer, // Assuming new chat is analyzer screen
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.keyboard_alt_outlined, // New Icon
              title: 'Custom Keyboard',       // New Title
              route: AppRouter.keyboard,        // New Route
              currentRoute: currentRoute,
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('History'),
              selected: currentRoute == '/history', // Add history route later
              onTap: () {
                // TODO: Implement History screen navigation
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              selected: currentRoute == '/settings', // Add settings route later
              onTap: () {
                // TODO: Implement Settings screen navigation
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to reduce code duplication
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
      onTap: () {
        Navigator.pop(context); // Close the drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
