import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stremini_chatbot/overlay/chat_overlay_manager.dart';
import 'package:stremini_chatbot/screens/chat_screen.dart';
import 'package:stremini_chatbot/utils/system_overlay_controller.dart';

// IMPORTANT: Define Global Key for the Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    // 1. Wrap the entire application in ProviderScope
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stremini Chat App',
      // 2. Assign the key to MaterialApp
      navigatorKey: navigatorKey,

      // 3. The Builder wraps the Navigator and injects the overlay logic
      builder: (context, child) {
        final appContent = child ?? const SizedBox();

        return SystemOverlayController(
          navigatorKey: navigatorKey,
          child: ChatOverlayManager(
            // Handles the floating icon and chat window
            child: appContent,
          ),
        );
      },
      // You can replace this with your actual home screen
      home: const Scaffold(
        body: ChatScreen(),
      ),
    );
  }
}
