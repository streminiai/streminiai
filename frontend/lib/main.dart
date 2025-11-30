import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Screens
import 'screens/home_screen.dart';

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

// Wrapper widget - NO floating widgets, everything is native Android
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
        
        if (action == 'scan_complete') {
          final scannedText = event['text'] as String?;
          if (scannedText != null && scannedText.isNotEmpty) {
            debugPrint('Scanned text: $scannedText');
          }
        } else if (action == 'scan_error') {
          final error = event['error'] as String?;
          debugPrint('Scan error: $error');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Just the main app content - NO floating widgets
    // All floating functionality is handled by native Android service
    return const HomeScreen();
  }
}
