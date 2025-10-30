import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screens/chat_screen.dart';
import '../widgets/draggable_chat_icon.dart';

class ChatOverlayManager extends StatefulWidget {
  final Widget child;
  const ChatOverlayManager({super.key, required this.child});

  @override
  State<ChatOverlayManager> createState() => _ChatOverlayManagerState();
}

class _ChatOverlayManagerState extends State<ChatOverlayManager> {
  Offset _bubblePosition = const Offset(300, 500);
  late OverlayEntry _overlayEntry;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
    });
  }

  void updatePosition(Offset newOffset) {
    setState(() => _bubblePosition = newOffset);
    _overlayEntry.markNeedsBuild();
  }

  void toggleChatPanel() {
    setState(() => _isMaximized = !_isMaximized);
    _overlayEntry.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      opaque: false,
      builder: (context) {
        return _isMaximized
            ? _buildMaximizedChat(context)
            : DraggableChatIcon(
                position: _bubblePosition,
                onDragEnd: updatePosition,
                onTap: toggleChatPanel,
              );
      },
    );
  }

  Widget _buildMaximizedChat(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            const ChatScreen(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: toggleChatPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


