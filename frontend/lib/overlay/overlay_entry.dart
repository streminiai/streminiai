import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// This is the actual UI builder for the overlay. The entrypoint that the
// Android service resolves will be declared in main.dart and will forward here.
void overlayMainEntry() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _OverlayBubbleApp());
}

class _OverlayBubbleApp extends StatelessWidget {
  const _OverlayBubbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.transparent),
      home: const _OverlayBubble(),
    );
  }
}

class _OverlayBubble extends StatelessWidget {
  const _OverlayBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Close overlay; bringing app to foreground is platform-specific.
        await FlutterOverlayWindow.closeOverlay();
      },
      child: Container(
        alignment: Alignment.center,
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}
