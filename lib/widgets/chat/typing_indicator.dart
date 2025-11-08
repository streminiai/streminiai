// lib/widgets/chat/typing_indicator.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// Typing indicator for AI responses (three animated dots)
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppConstants.primaryColor,
            ),
          ),

          SizedBox(width: AppConstants.spaceS),

          // Typing bubble
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: AppDecorations.aiBubbleDecoration,
            child: _AnimatedDots(),
          ),
        ],
      ),
    );
  }
}

/// Three animated dots
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.typingAnimationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (Curves.easeInOut.transform(value) * 0.5);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppConstants.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Compact typing indicator (for minimal UI)
class CompactTypingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const CompactTypingIndicator({
    Key? key,
    this.color,
    this.size = 6,
  }) : super(key: key);

  @override
  State<CompactTypingIndicator> createState() => _CompactTypingIndicatorState();
}

class _CompactTypingIndicatorState extends State<CompactTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppConstants.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.15;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (Curves.easeInOut.transform(value) * 2 - 1).abs();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Typing indicator with text
class TypingWithText extends StatelessWidget {
  final String text;

  const TypingWithText({
    Key? key,
    this.text = 'AI is typing',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      child: Row(
        children: [
          CompactTypingIndicator(size: 4),
          SizedBox(width: AppConstants.spaceS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppConstants.captionSize,
              color: AppConstants.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
