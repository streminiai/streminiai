// lib/overlays/overlay_main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import necessary providers and controllers
import 'package:stremini_chatbot/features/chat_provider.dart';
import 'package:stremini_chatbot/features/translation_provider.dart';
import 'package:stremini_chatbot/features/security_provider.dart';
import 'package:stremini_chatbot/features/keyboard_provider.dart';
import 'package:stremini_chatbot/features/settings_provider.dart';
import 'package:stremini_chatbot/services/stremini_api_service.dart';
import 'package:stremini_chatbot/widgets/floating_widget/feature_selection_menu.dart';
import 'package:stremini_chatbot/widgets/floating_widget/floating_bubble.dart';

// Import the feature specific overlays
import 'package:stremini_chatbot/widgets/floating_widget/chat_overlay.dart';
import 'package:stremini_chatbot/widgets/translation/translation_overlay.dart';
import 'package:stremini_chatbot/widgets/security/security_scanner.dart';
import 'package:stremini_chatbot/widgets/keyboard/ai_keyboard_interface.dart';
import 'package:stremini_chatbot/screens/settings_screen.dart'; // We'll show this in a separate window, but its state is used.


// The main entry point for the floating overlay interface
class OverlayMain extends StatelessWidget {
  const OverlayMain({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize core services and controllers
    // We assume SettingsProvider is provided higher up (e.g., in main.dart)
    final settingsProvider = context.read<SettingsProvider>();
    final apiService = StreminiApiService(settingsProvider: settingsProvider);

    // 2. Wrap the entire overlay UI with all necessary feature providers
    return MultiProvider(
      providers: [
        // Core Feature Controllers
        ChangeNotifierProvider(create: (_) => FeatureController()),
        
        // Feature Providers relying on the API Service
        ChangeNotifierProvider(create: (_) => ChatProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => TranslationProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => SecurityProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => KeyboardProvider(apiService: apiService)),
        // Note: AutomationProvider would be initialized here too, but its UI is not part of the current overlay flow.
      ],
      // 3. The actual floating UI logic
      child: const _OverlayContent(),
    );
  }
}

// Internal widget to manage the display state based on the FeatureController
class _OverlayContent extends StatelessWidget {
  const _OverlayContent();

  @override
  Widget build(BuildContext context) {
    // Watch the feature controller to determine which UI to show
    final featureController = context.watch<FeatureController>();
    final activeFeature = featureController.activeFeature;
    
    // Determine if any overlay panel is open (excluding the main menu/bubble)
    final bool isPanelOpen = activeFeature != null && activeFeature != StreminiFeature.settings;

    // --- Conditional Overlay Logic ---

    // 1. Determine which feature panel widget to display
    Widget? activePanelWidget;
    switch (activeFeature) {
      case StreminiFeature.chat:
        // Use ChatProvider state
        activePanelWidget = const ChatOverlay();
        break;
      case StreminiFeature.translate:
        // Use TranslationProvider state
        activePanelWidget = const TranslationOverlayWidget();
        break;
      case StreminiFeature.security:
        // Use SecurityProvider state
        activePanelWidget = const SecurityScannerWidget();
        break;
      case StreminiFeature.keyboard:
        // The Keyboard UI is typically a bar at the bottom, so it needs custom alignment.
        // For demonstration, we'll align it to the bottom.
        activePanelWidget = Align(
          alignment: Alignment.bottomCenter,
          child: AIKeyboardInterface(
            onApplyText: (newText) {
              // In a real scenario, this callback would trigger a native call
              // to insert the text into the underlying app's input field.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Applied modified text: "$newText"')),
              );
              context.read<FeatureController>().closeOverlay();
            },
          ),
        );
        break;
      case StreminiFeature.settings:
        // Settings typically opens the full-screen Flutter app, not an overlay.
        // We simulate a notification that the app is opening.
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Stremini Settings App...')),
          );
          featureController.closeOverlay(); // Close the menu when switching to app view
        });
        break;
      case StreminiFeature.automation:
      case null:
        // No active panel, or Automation (which typically has no persistent UI)
        break;
    }


    return Stack(
      children: [
        // --- Layer 1: The Active Feature Panel (Chat, Translation, Security, Keyboard) ---
        if (isPanelOpen && activePanelWidget != null)
          Positioned.fill(
            child: Container(
              // Tap listener to dismiss the panel when tapping outside
              child: activePanelWidget,
            ),
          ),
          
        // --- Layer 2: The Floating Bubble/Menu ---
        Align(
          alignment: Alignment.bottomRight, // Default position for the bubble
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0, right: 20.0),
            child: FloatingBubble(
              // If a panel is open, the bubble transforms into the feature selection menu
              isMenuOpen: activeFeature != null && activeFeature != StreminiFeature.keyboard,
              child: activeFeature == null 
                  ? null // Bubble icon when menu is closed
                  : activeFeature == StreminiFeature.keyboard
                      ? null // Keep only the keyboard interface when keyboard is active
                      : const FeatureSelectionMenu(), // The circular menu
              onTap: () {
                 // Toggle the menu if no panel is open, otherwise close the panel
                 if (!isPanelOpen) {
                    featureController.setActiveFeature(StreminiFeature.chat); // Default to chat on first tap
                 } else {
                    featureController.closeOverlay();
                 }
              },
            ),
          ),
        ),
      ],
    );
  }
}
