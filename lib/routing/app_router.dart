import 'package:flutter/material.dart';
import 'package:stremniapp/screens/home_screen.dart';
import 'package:stremniapp/screens/chatbot_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String chatbot = '/chatbot';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case chatbot:
        return MaterialPageRoute(builder: (_) => const ChatbotScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
