import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'overlay/chat_overlay_manager.dart';
import 'utils/system_overlay_controller.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const ProviderScope(child: StreminiChatbotApp()));
}

class StreminiChatbotApp extends StatelessWidget {
  const StreminiChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stremini AI Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SystemOverlayController(
        child: ChatOverlayManager(
          child: ChatScreen(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
