// import 'package:flutter/material.dart';
// import '../screens/chat_screen.dart';

// class MiniChatOverlay extends StatelessWidget {
//   const MiniChatOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Center(
//         child: SizedBox(
//           height: 420,
//           width: 320,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Material(
//               elevation: 8,
//               child: Column(
//                 children: [
//                   // draggable bar / header
//                   Container(
//                     height: 40,
//                     color: Theme.of(context).primaryColor,
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 8),
//                         const Icon(Icons.chat_bubble, color: Colors.white),
//                         const SizedBox(width: 8),
//                         const Expanded(
//                           child: Text(
//                             "Mini Chat",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.open_in_full, color: Colors.white),
//                           onPressed: () {
//                             // expand to full app chat - close overlay and open app route
//                             // The overlay can't directly open the app UI; the recommended
//                             // behavior is to close overlay and rely on platform channels
//                             // or deep link to open the app. For now we close overlay.
//                             // The app's main can listen to intents and open chat.
//                             // Close overlay:
//                             // Note: Importing FlutterOverlayWindow here would be ideal,
//                             // but to avoid extra coupling we just close overlay via
//                             // a platform message in the app integration.
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close, color: Colors.white),
//                           onPressed: () {
//                             // close overlay - will be handled by overlay framework
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   // actual chat screen expanded inside the mini window
//                   const Expanded(
//                     child: ChatScreen(),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
