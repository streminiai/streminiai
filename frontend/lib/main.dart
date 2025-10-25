import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StreminiApp(),
    ),
  );
}

class StreminiApp extends StatelessWidget {
  const StreminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stremini AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blue,
          surface: Color(0xFF2A2A2A),
          background: Color(0xFF1A1A1A),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
