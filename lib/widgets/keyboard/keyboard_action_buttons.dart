// lib/widgets/keyboard/keyboard_action_buttons.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Grid of keyboard action buttons
class KeyboardActionButtons extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Function(String) onActionTap;

  const KeyboardActionButtons({
    Key? key,
    required this.actions,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: AppConstants.spaceM,
        mainAxisSpacing: AppConstants.spaceM,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return KeyboardActionButton(
          label: action['label'] as String,
          icon: action['icon'] as IconData,
          onTap: () => onActionTap(action['label'] as String),
        );
      },
    );
  }
}

/// Individual keyboard action button
class KeyboardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const KeyboardActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          AppHelpers.hapticFeedback(light: true);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.dividerColor,
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(AppConstants.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color ?? AppConstants.keyboardColor,
                size: 24,
              ),
              SizedBox(height: AppConstants.spaceS),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConstants.captionSize,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action bar (horizontal)
class QuickActionBar extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Function(String) onActionTap;

  const QuickActionBar({
    Key? key,
    required this.actions,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: EdgeInsets.only(right: AppConstants.spaceS),
            child: _QuickActionChip(
              label: action['label'] as String,
              icon: action['icon'] as IconData,
              onTap: () => onActionTap(action['label'] as String),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.cardDark,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppConstants.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppConstants.keyboardColor,
              ),
              SizedBox(width: AppConstants.spaceS),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConstants.bodySize,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact action button (icon only)
class CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const CompactActionButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppConstants.cardDark,
        shape: CircleBorder(),
        child: InkWell(
          onTap: () {
            AppHelpers.hapticFeedback(light: true);
            onTap();
          },
          customBorder: CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.dividerColor,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color ?? AppConstants.keyboardColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
