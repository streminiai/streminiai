import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DraggableChatIcon extends ConsumerStatefulWidget {
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
  ConsumerState<DraggableChatIcon> createState() => _DraggableChatIconState();
}

class _DraggableChatIconState extends ConsumerState<DraggableChatIcon>
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

    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.chat_bubble, 'action': widget.onOpenApp},
      {'icon': Icons.call, 'action': () => debugPrint("Call Tapped")},
      {'icon': Icons.videocam, 'action': () => debugPrint("Video Tapped")},
      {'icon': Icons.settings, 'action': () => debugPrint("Settings Tapped")},
      {'icon': Icons.close, 'action': widget.onTapMain},
    ];

    double startAngle;
    double endAngle;

    if (isOnRightSide) {
      startAngle = -90.0;
      endAngle = 90.0;
    } else {
      startAngle = -90.0;
      endAngle = 90.0;
    }

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
            // 1. The Radial Menu
            if (isRadial)
              SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: _buildRadialIcons(context)),

            // 2. The Main Floating Button
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

                // 1. Find the center point of the icon
                final centerOfIcon = _currentPosition.dx + (_iconSize / 2);

                // 2. Determine which half of the screen the center is in
                final isCloserToRight = centerOfIcon > (screenWidth / 2);

                // 3. Calculate the X position, snapping it to the closest edge
                final clampedX =
                    isCloserToRight ? (screenWidth - _iconSize) : 0.0;

                // 4. Calculate the Y position (still clamped to top/bottom)
                final clampedY = _currentPosition.dy
                    .clamp(topPadding, screenHeight - _iconSize);

                // 5. Update the position state with the snapped values
                _currentPosition = Offset(clampedX, clampedY);

                // Notify the parent manager of the final snapped position
                widget.onDragEnd(_currentPosition);
              },
              onTap: widget.onTapMain,
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
                  child: Icon(isRadial ? Icons.close : Icons.add,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
