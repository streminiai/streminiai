import 'package:flutter/material.dart';
import 'dart:math' as math;

class DraggableChatIcon extends StatefulWidget {
  final Offset position;
  final Function(Offset) onDragEnd;
  final String overlayMode; // New: external state drives the view
  final VoidCallback onTapMain; // New: tap to cycle mode (icon <-> radial)
  final VoidCallback onOpenApp; // New: action to maximize the chat

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

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start listener to handle external state changes
    _updateAnimation(widget.overlayMode == "radial");
  }

  @override
  void didUpdateWidget(DraggableChatIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _currentPosition = widget.position;
    }
    // Update animation state when the external overlayMode changes
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRadialIcons(BuildContext context) {
    const double radius = 100.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isOnRightSide =
        (_currentPosition.dx + (_iconSize / 2)) > (screenWidth / 2);

    // 5 Icons with their corresponding actions
    final List<Map<String, dynamic>> icons = [
      {
        'icon': Icons.chat_bubble,
        'action': widget.onOpenApp
      }, // Open App (Chat)
      {'icon': Icons.call, 'action': () => debugPrint("Call Tapped")},
      {'icon': Icons.videocam, 'action': () => debugPrint("Video Tapped")},
      {'icon': Icons.settings, 'action': () => debugPrint("Settings Tapped")},
      {
        'icon': Icons.close,
        'action': widget.onTapMain
      }, // TapMain will cycle back to "icon" mode
    ];

    double startAngle;
    double endAngle;

    if (isOnRightSide) {
      // Icon is on the right -> Fan should point LEFT (180 to 90 degrees)
      startAngle =-90.0;
      endAngle = 90.0;
    } else {
      // Icon is on the left -> Fan should point RIGHT (0 to 90 degrees)
      startAngle = -90.0;
      endAngle = 90.0;
    }

    // Ensure we don't divide by zero if fewer than 2 icons
    final double step = icons.length > 1
        ? (endAngle - startAngle).abs() / (icons.length - 1)
        : 0;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(icons.length, (index) {
        final double angleDegrees = isOnRightSide
            ? startAngle - (step * index)
            : startAngle + (step * index);

        final double angleRadians = angleDegrees * (math.pi / 180);

        final double x = radius * math.cos(angleRadians);
        final double y = -radius * math.sin(angleRadians);

        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final double currentX = x * _expandAnimation.value;
            final double currentY = y * _expandAnimation.value;
            final double scale = _expandAnimation.value;

            return Transform.translate(
              offset: Offset(currentX, currentY),
              child: Transform.scale(
                scale: scale,
                child: FloatingActionButton.small(
                  heroTag: "radial_$index",
                  backgroundColor: Colors.indigoAccent,
                  onPressed: () {
                    if (scale > 0.9) {
                      // Prevent interaction until expanded
                      icons[index]['action']();
                    }
                  },
                  child: Icon(icons[index]['icon'], color: Colors.white),
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
            // 1. The Radial Menu (Renders only if in radial mode)
            if (isRadial)
              SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: _buildRadialIcons(context)),

            // 2. The Main Floating Button
            GestureDetector(
              onPanUpdate: (details) {
                if (isRadial)
                  widget.onTapMain(); // Collapse menu if dragging starts

                setState(() {
                  _currentPosition += details.delta;
                });
              },
              onPanEnd: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                // Clamp position within screen bounds
                _currentPosition = Offset(
                  _currentPosition.dx.clamp(0.0, screenWidth - _iconSize),
                  _currentPosition.dy.clamp(0.0, screenHeight - _iconSize),
                );

                widget.onDragEnd(_currentPosition);
              },
              onTap: widget.onTapMain, // Tap cycles mode (icon <-> radial)
              child: RotationTransition(
                turns: isRadial
                    ? _rotateAnimation
                    : const AlwaysStoppedAnimation(0.0),
                child: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: isRadial ? Colors.red : Colors.indigo,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Icon(
                      isRadial
                          ? Icons.close
                          : Icons.add, // Shows 'X' when expanded
                      color: Colors.white,
                      size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
