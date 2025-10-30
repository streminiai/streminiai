import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'utils/overlay_permission.dart';
import 'overlay/overlay_entry.dart' as overlay;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestOverlayPermissionIfNeeded();
  runApp(const ProviderScope(child: StreminiChatbotApp()));
}

// The Android overlay service resolves this symbol by name. Keeping it in
// main.dart ensures the VM can find it. It forwards to our overlay UI.
@pragma('vm:entry-point')
void overlayMain() {
  overlay.overlayMainEntry();
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
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
