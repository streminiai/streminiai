import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:stremniapp/routing/app_router.dart';
import 'package:stremniapp/theme/app_theme.dart';

// Overlay entry point - runs in separate isolate
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StreminiChatbot());
}

class StreminiChatbot extends StatelessWidget {
  const StreminiChatbot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stremini Chatbot',
      theme: AppTheme.darkTheme,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

// The floating overlay widget that appears over other apps
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  bool _isAnalyzing = false;
  Color _buttonColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    // Listen for messages from main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'analyzing') {
        setState(() => _isAnalyzing = true);
      } else if (data == 'complete') {
        setState(() {
          _isAnalyzing = false;
          _buttonColor = Colors.green;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _buttonColor = Colors.blue);
        });
      } else if (data == 'scam_detected') {
        setState(() {
          _isAnalyzing = false;
          _buttonColor = Colors.red;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // Send message to main app to trigger analysis
          FlutterOverlayWindow.shareData('analyze_screen');
        },
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: _buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _isAnalyzing
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
}
