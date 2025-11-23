import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stremini AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your Digital Bodyguard',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Navigation items
            _buildItem(
              context: context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              title: 'Home',
              route: AppRouter.home,
              currentRoute: currentRoute,
            ),
            _buildItem(
              context: context,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              title: 'AI Chat',
              route: AppRouter.chat,
              currentRoute: currentRoute,
            ),
            _buildItem(
              context: context,
              icon: Icons.document_scanner_outlined,
              selectedIcon: Icons.document_scanner,
              title: 'Content Analyzer',
              route: AppRouter.analyzer,
              currentRoute: currentRoute,
            ),
            _buildItem(
              context: context,
              icon: Icons.shield_outlined,
              selectedIcon: Icons.shield,
              title: 'Floating Bubble',
              route: AppRouter.systemOverlay,
              currentRoute: currentRoute,
            ),

            const Divider(height: 32),

            _buildItem(
              context: context,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              title: 'Settings',
              route: AppRouter.settings,
              currentRoute: currentRoute,
            ),

            // About
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAbout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String route,
    required String? currentRoute,
  }) {
    final isSelected = currentRoute == route;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? theme.primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  void _showAbout(BuildContext context) {
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
