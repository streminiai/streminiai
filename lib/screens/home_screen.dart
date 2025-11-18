import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/routing/app_drawer.dart'; // ✅ CHANGED: Import from routing, not widgets
import 'package:stremniapp/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Greeting Section
              Text('Good afternoon! 👋', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text('Your AI assistant is ready', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              
              // Quick Chat Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                      Navigator.pushNamed(context, AppRouter.chat);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quick Chat', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),

              // Stats Section
              Row(
                children: const [
                  _StatBlock(value: '24', label: 'Threats Blocked'),
                  SizedBox(width: 16),
                  _StatBlock(value: 'AI', label: 'Always Active'),
                  SizedBox(width: 16),
                  _StatBlock(value: '99%', label: 'Protection'),
                ],
              ),
              const SizedBox(height: 32),

              // AI Features Section
              Text('AI Features', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              
              // Smart Chatbot - Goes to CHAT screen
              FeatureCard(
                icon: Icons.chat_bubble_outline,
                title: 'Smart Chatbot',
                subtitle: 'Engage in intelligent conversations',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.chat);
                },
              ),
              
              // Digital Bodyguard
              FeatureCard(
                icon: Icons.security_outlined,
                title: 'Digital Bodyguard',
                subtitle: 'Real-time scan and phishing detection',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.bodyguard);
                },
              ),
              
              // Screen Analyzer
              FeatureCard(
                icon: Icons.shield_outlined,
                title: 'Screen Analyzer (System-wide)',
                subtitle: 'Floating button to analyze any screen',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.systemOverlay);
                },
              ),
              
              // Content Analyzer
              FeatureCard(
                icon: Icons.document_scanner_outlined,
                title: 'Content Analyzer',
                subtitle: 'Analyze text and messages',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.analyzer);
                },
              ),
              
              // Auto Task
              FeatureCard(
                icon: Icons.task_alt_outlined,
                title: 'Auto Task',
                subtitle: 'Automate your daily tasks',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.autoTask);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for the stats section
class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({Key? key, required this.value, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
