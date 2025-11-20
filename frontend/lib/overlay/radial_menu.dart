// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// class RadialMenuOverlay extends StatelessWidget {
//   const RadialMenuOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 3 buttons spanning 180 degrees: -90 (up), -45 (up-right), -135 (up-left)
//     return Material(
//       color: Colors.transparent,
//       child: Center(
//         child: SizedBox(
//           height: 220,
//           width: 220,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               _menuButton(Icons.message, "open-mini-chat", angle: -90),
//               _menuButton(Icons.settings, "do-settings", angle: -45),
//               _menuButton(Icons.person, "do-profile", angle: -135),
//               // center close/hub
//               GestureDetector(
//                 onTap: () => FlutterOverlayWindow.closeOverlay(),
//                 child: CircleAvatar(
//                   radius: 26,
//                   backgroundColor: Colors.white,
//                   child: Icon(Icons.close, color: Colors.black54),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _menuButton(IconData icon, String action, {required double angle}) {
//     final double rad = angle * pi / 180;
//     final Offset offset = Offset(86 * cos(rad), 86 * sin(rad));
//     return Transform.translate(
//       offset: offset,
//       child: GestureDetector(
//         onTap: () {
//           // perform action by showing another overlay or sending intent
//           if (action == "open-mini-chat") {
//             FlutterOverlayWindow.showOverlay(
//               overlayTitle: "mini-chat",
//               overlayContent: "mini-window",
//               height: 420,
//               width: 320,
//               enableDrag: true,
//             );
//           } else {
//             // placeholder for other actions
//             FlutterOverlayWindow.closeOverlay();
//           }
//         },
//         child: CircleAvatar(
//           radius: 28,
//           backgroundColor: Colors.white,
//           child: Icon(icon, color: Colors.black87),
//         ),
//       ),
//     );
//   }
// }
