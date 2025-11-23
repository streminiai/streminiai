import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/routing/app_drawer.dart';
import 'package:stremniapp/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stremini AI'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Welcome! 👋',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI assistant is ready to protect you',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Quick Chat Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRouter.chat),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Start AI Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: const [
                _StatCard(value: '24', label: 'Threats\nBlocked'),
                SizedBox(width: 12),
                _StatCard(value: 'AI', label: 'Always\nActive'),
                SizedBox(width: 12),
                _StatCard(value: '99%', label: 'Protection\nRate'),
              ],
            ),
            const SizedBox(height: 32),

            // Features Section
            Text('AI Features', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            FeatureCard(
              icon: Icons.chat_bubble_outline,
              title: 'Smart Chatbot',
              subtitle: 'Engage in intelligent conversations',
              onTap: () => Navigator.pushNamed(context, AppRouter.chat),
            ),

            FeatureCard(
              icon: Icons.shield_outlined,
              title: 'Floating Bubble',
              subtitle: 'System-wide protection overlay',
              onTap: () => Navigator.pushNamed(context, AppRouter.systemOverlay),
            ),

            FeatureCard(
              icon: Icons.document_scanner_outlined,
              title: 'Content Analyzer',
              subtitle: 'Analyze text and images for threats',
              onTap: () => Navigator.pushNamed(context, AppRouter.analyzer),
            ),

            FeatureCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Manage permissions and preferences',
              onTap: () => Navigator.pushNamed(context, AppRouter.settings),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
