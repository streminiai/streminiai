import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

/// --------------------------------------------------------------
/// 🔵 MAIN APP
/// --------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow Radial Menu',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// --------------------------------------------------------------
/// 🔵 HOME SCREEN WITH DRAGGABLE BUTTON
/// --------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Offset buttonPosition = const Offset(100, 300);
  String overlayMode = "closed";

  void onDragEnd(Offset newPos) {
    setState(() {
      buttonPosition = newPos;
    });
  }

  void toggleRadial() {
    setState(() {
      overlayMode = overlayMode == "closed" ? "radial" : "closed";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Example background
          Container(color: Colors.black87),

          // Draggable Chat Icon + Radial Menu
          DraggableChatIcon(
            position: buttonPosition,
            overlayMode: overlayMode,
            onDragEnd: onDragEnd,
            onTapMain: toggleRadial,
            onOpenApp: () {},
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------------------------
/// 🔵 GLOW CIRCLE BUTTON
/// --------------------------------------------------------------
class GlowCircleButton extends StatelessWidget {
  final Widget icon; // Accepts Icon or ImageIcon
  final double size;
  final VoidCallback onTap;

  const GlowCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFF23A6E2),
              Color(0xFFAA75F4),
              Color(0xFF0066FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF23A6E2),
              blurRadius: 3,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color(0xFFAA75F4),
              blurRadius: 3,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

/// --------------------------------------------------------------
/// 🔵 DRAGGABLE CHAT ICON + RADIAL MENU
/// --------------------------------------------------------------
class DraggableChatIcon extends StatefulWidget {
  final Offset position;
  final Function(Offset) onDragEnd;
  final String overlayMode;
  final VoidCallback onTapMain;
  final VoidCallback onOpenApp;

  const DraggableChatIcon({
    super.key,
    required this.position,
    required this.onDragEnd,
    required this.overlayMode,
    required this.onTapMain,
    required this.onOpenApp,
  });

  @override
  State<DraggableChatIcon> createState() => _DraggableChatIconState();
}

class _DraggableChatIconState extends State<DraggableChatIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Offset _currentPosition;

  static const double _iconSize = 60.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _updateAnimation(widget.overlayMode == "radial");
  }

  @override
  void didUpdateWidget(DraggableChatIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _currentPosition = widget.position;
    }
    if (oldWidget.overlayMode != widget.overlayMode) {
      _updateAnimation(widget.overlayMode == "radial");
    }
  }

  void _updateAnimation(bool isRadial) {
    if (isRadial) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// --------------------------------------------------------------
  /// 🔵 RADIAL MENU
  /// --------------------------------------------------------------
  Widget _buildRadialIcons(BuildContext context) {
    const double radius = 110.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isOnRightSide =
        (_currentPosition.dx + (_iconSize / 2)) > (screenWidth / 2);

    // You can mix IconData and ImageIcon here
    final List<Map<String, dynamic>> icons = [
      {'icon': Icon(Icons.message, color: Colors.white), 'action': () {}},
      {
        'icon': ImageIcon(
          AssetImage('assets/icons/my_icon.png'),
          color: Colors.white,
        ),
        'action': () {}
      },
      {'icon': Icon(Icons.settings, color: Colors.white), 'action': () {}},
      {'icon': Icon(Icons.keyboard, color: Colors.white), 'action': () {}},
      {'icon': Icon(Icons.shield, color: Colors.white), 'action': () {}},
    ];

    double startAngle = isOnRightSide ? 90.0 : 90.0;
    double endAngle = isOnRightSide ? 270.0 : -90.0;
    final double step = (endAngle - startAngle) / (icons.length - 1);

    return Stack(
      alignment: Alignment.center,
      children: List.generate(icons.length, (index) {
        final double angle = startAngle + (index * step);
        final double rad = angle * (math.pi / 180.0);
        final double x = radius * math.cos(rad);
        final double y = radius * math.sin(rad);

        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(
                x * _expandAnimation.value,
                -y * _expandAnimation.value,
              ),
              child: Opacity(
                opacity: _expandAnimation.value.clamp(0.0, 1.0),
                child: GlowCircleButton(
                  icon: icons[index]['icon'],
                  size: 55,
                  onTap: () => icons[index]['action'](),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRadial = widget.overlayMode == "radial";

    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isRadial)
              SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: _buildRadialIcons(context),
              ),
            GestureDetector(
              onPanUpdate: (details) {
                if (isRadial) widget.onTapMain();
                setState(() {
                  _currentPosition += details.delta;
                });
              },
              onPanEnd: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final topPadding = MediaQuery.of(context).padding.top;
                final centerX = _currentPosition.dx + (_iconSize / 2);
                final snapRight = centerX > (screenWidth / 2);

                final clampedX = snapRight ? (screenWidth - _iconSize) : 0.0;
                final clampedY = _currentPosition.dy
                    .clamp(topPadding, screenHeight - _iconSize);

                _currentPosition = Offset(clampedX, clampedY);
                widget.onDragEnd(_currentPosition);
              },
              onTap: widget.onTapMain,
              child: RotationTransition(
                turns: isRadial
                    ? _rotateAnimation
                    : const AlwaysStoppedAnimation(0.0),
                child: GlowCircleButton(
                  icon: ImageIcon(
                    AssetImage('assets/logo.jpg'),
                    color: Colors.white,
                    size: 40,
                  ),
                  size: 70,
                  onTap: widget.onTapMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
