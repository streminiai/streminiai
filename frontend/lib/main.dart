import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Screens
import 'screens/home_screen.dart';
import 'widgets/whatsapp_floating_chat.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
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
      title: 'Stremini AI',
      navigatorKey: navigatorKey,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF23A6E2),
      ),
      home: const AppWrapper(),
    );
  }
}

// Wrapper widget that manages overlay layers
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  static const EventChannel _eventChannel = EventChannel('stremini.chat.overlay/events');

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _listenToOverlayEvents();
    }
  }

  void _listenToOverlayEvents() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final action = event['action'] as String?;
        
        if (action == 'open_floating_chat') {
          // Show WhatsApp-style floating chatbot
          ref.read(enhancedFloatingChatProvider.notifier).show();
        } else if (action == 'close_floating_chat') {
          // Hide floating chatbot
          ref.read(enhancedFloatingChatProvider.notifier).hide();
        } else if (action == 'open_scanner') {
          // TODO: Show scanner if needed
        } else if (action == 'close_scanner') {
          // TODO: Hide scanner if needed
        } else if (action == 'scan_complete') {
          // Process scan result
          final scannedText = event['text'] as String?;
          if (scannedText != null && scannedText.isNotEmpty) {
            // TODO: Handle scanned text
            debugPrint('Scanned text: $scannedText');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        const HomeScreen(),
        
        // HTML-style Floating Chatbot
        const HtmlStyleFloatingChat(),
      ],
    );
  }
}
