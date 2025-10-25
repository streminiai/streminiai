import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawer_provider.dart';
import '../providers/chat_provider.dart';

class NavigationDrawer extends ConsumerWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(drawerProvider.notifier).closeDrawer(),
      child: Container(
        color: Colors.black54,
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  right: BorderSide(color: Color(0xFF3A3A3A)),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildMenuItems(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search for features',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            // TODO: Navigate to home
          },
        ),
        _buildMenuItem(
          icon: Icons.add_box_outlined,
          label: 'New chat',
          onTap: () {
            // TODO: Start new chat
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          label: 'Settings',
          onTap: () {
            // TODO: Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildHistorySection() {
    final historyItems = [
      'How to change my pc pin',
      'How to block unwanted message',
      'what happened to netflix',
      'convert in dollars',
      'Remove number from spam',
      'name change',
      'India hotties news',
      'New intel chip',
      'Global Warming',
      'blocking contact',
      'Change device password',
    ];

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    historyItems[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    // TODO: Load chat history
                  },
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
