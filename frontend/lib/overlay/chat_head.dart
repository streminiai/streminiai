// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import '../screens/chat_screen.dart';
// import '../widgets/draggable_chat_icon.dart';

// /// -------------------- Overlay Widgets --------------------

// class ChatHeadOverlay extends StatelessWidget {
//   const ChatHeadOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 80,
//       height: 80,
//       child: Material(
//         shape: const CircleBorder(),
//         color: Colors.blue,
//         child: const Icon(Icons.chat, color: Colors.white),
//       ),
//     );
//   }
// }

// class RadialMenuOverlay extends StatelessWidget {
//   const RadialMenuOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 150,
//       height: 150,
//       child: Material(
//         color: Colors.transparent,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             FloatingActionButton(
//               onPressed: () {},
//               child: const Icon(Icons.message),
//             ),
//             Positioned(
//               top: 0,
//               child: FloatingActionButton(
//                 onPressed: () {},
//                 mini: true,
//                 child: const Icon(Icons.settings),
//               ),
//             ),
//             Positioned(
//               left: 0,
//               child: FloatingActionButton(
//                 onPressed: () {},
//                 mini: true,
//                 child: const Icon(Icons.camera),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class MiniChatOverlay extends StatelessWidget {
//   const MiniChatOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 320,
//       height: 420,
//       child: Material(
//         color: Colors.black.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(12),
//         child: Column(
//           children: [
//             // Header
//             Container(
//               height: 40,
//               color: Theme.of(context).primaryColor,
//               child: Row(
//                 children: [
//                   const SizedBox(width: 8),
//                   const Icon(Icons.chat_bubble, color: Colors.white),
//                   const SizedBox(width: 8),
//                   const Expanded(
//                     child: Text("Mini Chat",
//                         style: TextStyle(color: Colors.white)),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.open_in_full, color: Colors.white),
//                     onPressed: () {}, // expand to full chat
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     onPressed: () {}, // close overlay
//                   ),
//                 ],
//               ),
//             ),
//             const Expanded(child: ChatScreen()),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Factory function
// Widget getOverlayWidget(String content) {
//   switch (content) {
//     case "icon":
//       return const ChatHeadOverlay();
//     case "radial":
//       return const RadialMenuOverlay();
//     case "mini-window":
//       return const MiniChatOverlay();
//     default:
//       return const SizedBox.shrink();
//   }
// }

// /// -------------------- Overlay Manager --------------------

// class ChatOverlayManager extends StatefulWidget {
//   final Widget child;
//   const ChatOverlayManager({super.key, required this.child});

//   @override
//   State<ChatOverlayManager> createState() => _ChatOverlayManagerState();
// }

// class _ChatOverlayManagerState extends State<ChatOverlayManager> {
//   Offset _bubblePosition = const Offset(300, 500);
//   late OverlayEntry _overlayEntry;
//   bool _isMaximized = false;

//   String _currentOverlayContent = "icon";

//   @override
//   void initState() {
//     super.initState();
//     SchedulerBinding.instance.addPostFrameCallback((_) {
//       _overlayEntry = _createOverlayEntry();
//       Overlay.of(context).insert(_overlayEntry);
//     });
//   }

//   void updatePosition(Offset newOffset) {
//     setState(() => _bubblePosition = newOffset);
//     _overlayEntry.markNeedsBuild();
//   }

//   void toggleOverlayContent(String content) {
//     setState(() => _currentOverlayContent = content);
//     _overlayEntry.markNeedsBuild();
//   }

//   void toggleChatPanel() {
//     setState(() => _isMaximized = !_isMaximized);
//     _overlayEntry.markNeedsBuild();
//   }

//   OverlayEntry _createOverlayEntry() {
//     return OverlayEntry(
//       opaque: false,
//       builder: (context) {
//         if (_isMaximized) {
//           return Positioned.fill(child: _buildMaximizedChat(context));
//         }

//         // Draggable bubble
//         return Positioned(
//           left: _bubblePosition.dx,
//           top: _bubblePosition.dy,
//           child: DraggableChatIcon(
//             position: _bubblePosition,
//             onDragEnd: updatePosition,
//             onTap: () {
//               if (_currentOverlayContent == "icon") toggleChatPanel();
//             },
//             child: SizedBox(
//               width: _currentOverlayContent == "icon"
//                   ? 80
//                   : _currentOverlayContent == "radial"
//                       ? 150
//                       : 320,
//               height: _currentOverlayContent == "icon"
//                   ? 80
//                   : _currentOverlayContent == "radial"
//                       ? 150
//                       : 420,
//               child: getOverlayWidget(_currentOverlayContent),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMaximizedChat(BuildContext context) {
//     return Material(
//       color: Colors.black.withOpacity(0.9),
//       child: Stack(
//         children: [
//           const ChatScreen(),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 10,
//             right: 10,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: toggleChatPanel,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
