// lib/main.dart (Refreshed for full integration)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import all core files
import 'package:stremini_chatbot/features/settings_provider.dart';
import 'package:stremini_chatbot/screens/onboarding_screen.dart';
import 'package:stremini_chatbot/screens/home_screen.dart';
import 'package:stremini_chatbot/overlays/overlay_main.dart'; // Used as a primary route for overlay display

void main() {
  // Initialize and provide the core SettingsProvider globally
  // This must be done before the API Service, as it holds the key
  final settingsProvider = SettingsProvider(); 

  runApp(
    ChangeNotifierProvider(
      create: (_) => settingsProvider,
      child: const StreminiApp(),
    ),
  );
}

class StreminiApp extends StatelessWidget {
  const StreminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // You would typically check if onboarding is complete here
    final bool hasCompletedOnboarding = true; // Placeholder for logic

    return MaterialApp(
      title: 'Stremini AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.grey.shade100,
        useMaterial3: true,
      ),
      // Define main routes
      initialRoute: hasCompletedOnboarding ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        // Add other screens if needed, e.g., settings_screen.dart
        // You might use the native channel to start the overlay service from HomeScreen.
      },
      // When developing the overlay, you might temporarily use it here for testing:
      // home: const OverlayMain(), 
    );
  }
}
