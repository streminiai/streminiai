// lib/screens/feature_config_screen.dart
import 'package:flutter/material.dart';

// This screen is a placeholder to show where detailed settings for features (like 
// Chat, Automation, etc.) would be implemented.
class FeatureConfigScreen extends StatelessWidget {
  final String featureName;
  
  const FeatureConfigScreen({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$featureName Configuration'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, color: Colors.yellow.shade600, size: 50),
              const SizedBox(height: 20),
              Text(
                'Advanced settings for $featureName will be configured here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Examples: Custom prompts, trigger phrases, default tones, etc.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
