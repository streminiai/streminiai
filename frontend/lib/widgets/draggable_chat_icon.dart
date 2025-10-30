import 'package:flutter/material.dart';

class DraggableChatIcon extends StatefulWidget {
  final Offset position;
  final Function(Offset) onDragEnd;
  final VoidCallback onTap;

  const DraggableChatIcon({
    super.key,
    required this.position,
    required this.onDragEnd,
    required this.onTap,
  });

  @override
  State<DraggableChatIcon> createState() => _DraggableChatIconState();
}

class _DraggableChatIconState extends State<DraggableChatIcon> {
  late Offset _currentPosition;
  final double iconSize = 60.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            _currentPosition += details.delta;
          });
        },
        onPanEnd: (details) {
          widget.onDragEnd(_currentPosition);
        },
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.indigo,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.forum, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}


