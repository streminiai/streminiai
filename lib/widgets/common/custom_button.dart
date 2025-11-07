// lib/widgets/common/custom_button.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Custom button widget matching app theme
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isSmall;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = backgroundColor ?? AppConstants.primaryColor;
    final foregroundColor = textColor ?? AppConstants.textPrimary;
    
    final buttonHeight = height ?? (isSmall ? 40.0 : 48.0);
    final fontSize = isSmall ? 13.0 : AppConstants.bodySize;
    
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonColor,
                side: BorderSide(color: buttonColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : AppConstants.spaceL,
                ),
              ),
              child: _buildButtonChild(fontSize, buttonColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : () {
                AppHelpers.hapticFeedback(light: true);
                onPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: foregroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : AppConstants.spaceL,
                ),
              ),
              child: _buildButtonChild(fontSize, foregroundColor),
            ),
    );
  }

  Widget _buildButtonChild(double fontSize, Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: AppConstants.spaceS),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Icon button with consistent styling
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed == null ? null : () {
        AppHelpers.hapticFeedback(light: true);
        onPressed?.call();
      },
      icon: Icon(icon, size: size),
      color: color ?? AppConstants.textPrimary,
      style: backgroundColor != null
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            )
          : null,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Floating action button with feature color
class FeatureButton extends StatelessWidget {
  final String feature;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isExpanded;

  const FeatureButton({
    Key? key,
    required this.feature,
    required this.icon,
    required this.onPressed,
    this.isExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.getFeatureColor(feature);

    return FloatingActionButton.extended(
      onPressed: () {
        AppHelpers.hapticFeedback();
        onPressed();
      },
      backgroundColor: color,
      elevation: 4,
      icon: Icon(icon),
      label: isExpanded ? Text(feature) : SizedBox.shrink(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isExpanded ? 16 : AppConstants.bubbleBorderRadius,
        ),
      ),
    );
  }
}
