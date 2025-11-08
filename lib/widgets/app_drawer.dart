
import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Getting the current route to highlight the active item
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 80), // Spacer for status bar and header
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: currentRoute == AppRouter.home,
              onTap: () {
                Navigator.pop(context); // Close the drawer
                if (currentRoute != AppRouter.home) {
                  Navigator.pushReplacementNamed(context, AppRouter.home);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('New Chat'),
              // Example of how to handle selection
              selected: currentRoute == AppRouter.analyzer, // Assuming new chat is analyzer screen
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != AppRouter.analyzer) {
                  Navigator.pushReplacementNamed(context, AppRouter.analyzer);
                }
              },
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
}
