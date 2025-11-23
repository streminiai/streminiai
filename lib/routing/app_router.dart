import 'package:flutter/material.dart';
import 'package:stremniapp/screens/home_screen.dart';
import 'package:stremniapp/screens/screen_analyzer_screen.dart';
import 'package:stremniapp/screens/system_overlay_screen.dart';
import 'package:stremniapp/screens/custom_keyboard_screen.dart';
import 'package:stremniapp/screens/chatbot_screen.dart';
import 'package:stremniapp/screens/settings_screen.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class AppRouter {
  static const String home = '/home';
  static const String chat = '/chat';
  static const String analyzer = '/analyzer';
  static const String systemOverlay = '/system_overlay';
  static const String keyboard = '/keyboard';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget screen;

    switch (settings.name) {
      case home:
        screen = const HomeScreen();
        break;

      case chat:
        screen = const ChatbotScreen();
        break;

      case analyzer:
        screen = const ScreenAnalyzerScreen();
        break;

      case systemOverlay:
        screen = const SystemOverlayScreen();
        break;

      case keyboard:
        screen = const CustomKeyboardScreen();
        break;

      case AppRouter.settings:
        screen = const SettingsScreen();
        break;

      default:
        screen = Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          drawer: const AppDrawer(),
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        );
    }

    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }
}
