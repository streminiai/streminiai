import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/floating_chat_widget.dart';
import '../providers/chat_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../utils/overlay_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      await OverlayController.showBubble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChatExpanded = ref.watch(chatExpandedProvider);

    return PopScope(
      canPop: !isChatExpanded,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isChatExpanded) {
          ref.read(chatExpandedProvider.notifier).minimize();
          OverlayController.showBubble();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.apps,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your App Content',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chatbot is available in the floating widget',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const FloatingChatWidget(),
          ],
        ),
      ),
    );
  }
}

