import 'package:flutter/material.dart';
import 'package:stremniapp/screens/home_screen.dart';
import 'package:stremniapp/screens/screen_analyzer_screen.dart';
import 'package:stremniapp/screens/system_overlay_screen.dart';
import 'package:stremniapp/screens/custom_keyboard_screen.dart';
import 'package:stremniapp/screens/chatbot_screen.dart';
import 'package:stremniapp/routing/app_drawer.dart';

// Placeholder screens for other features
class VoiceControlScreen extends StatelessWidget {
  const VoiceControlScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Voice Control')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Voice Control Screen')),
      );
}

class AutoTaskScreen extends StatelessWidget {
  const AutoTaskScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Auto Task')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Auto Task Screen')),
      );
}

class DigitalBodyguardScreen extends StatelessWidget {
  const DigitalBodyguardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Digital Bodyguard')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Digital Bodyguard Screen')),
      );
}

class AppRouter {
  static const String voice = '/voice';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String analyzer = '/analyzer';
  static const String systemOverlay = '/system_overlay';
  static const String autoTask = '/auto_task';
  static const String bodyguard = '/bodyguard';
  static const String keyboard = '/keyboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget screen;
    switch (settings.name) {
      case voice:
        screen = const VoiceControlScreen();
        break;
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
      case autoTask:
        screen = const AutoTaskScreen();
        break;
      case bodyguard:
        screen = const DigitalBodyguardScreen();
        break;
      case keyboard:
        screen = const CustomKeyboardScreen();
        break;
      default:
        screen = Scaffold(
          appBar: AppBar(),
          drawer: const AppDrawer(),
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        );
    }
    return MaterialPageRoute(builder: (_) => screen);
  }
}
