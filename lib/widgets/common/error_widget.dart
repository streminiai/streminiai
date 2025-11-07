// lib/widgets/common/error_widget.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'custom_button.dart';

/// Error display widget with retry option
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool isFullScreen;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.onRetry,
    this.icon,
    this.isFullScreen = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: isFullScreen ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon ?? Icons.error_outline,
          size: 64,
          color: AppConstants.securityColor,
        ),
        SizedBox(height: AppConstants.spaceL),
        Text(
          'Oops! Something went wrong',
          style: TextStyle(
            fontSize: AppConstants.titleSize,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.spaceS),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceXL),
          child: Text(
            message,
            style: TextStyle(
              fontSize: AppConstants.bodySize,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(height: AppConstants.spaceL),
          CustomButton(
            text: 'Try Again',
            onPressed: onRetry,
            icon: Icons.refresh,
            width: 160,
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Center(child: content);
    }

    return content;
  }
}

/// Network error widget
class NetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkError({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorDisplay(
      message: 'No internet connection. Please check your network settings and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppConstants.spaceL),
            Text(
              title,
              style: TextStyle(
                fontSize: AppConstants.titleSize,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spaceS),
            Text(
              message,
              style: TextStyle(
                fontSize: AppConstants.bodySize,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              SizedBox(height: AppConstants.spaceL),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error banner (dismissible)
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    Key? key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppConstants.spaceM),
      padding: EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: AppConstants.securityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.securityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppConstants.securityColor,
            size: 24,
          ),
          SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: AppConstants.bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppConstants.captionSize,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              color: AppConstants.securityColor,
              iconSize: 20,
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close),
              color: AppConstants.textSecondary,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

/// Inline error message
class InlineError extends StatelessWidget {
  final String message;

  const InlineError({
    Key? key,
    required this.message,
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
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppConstants.securityColor,
          ),
          SizedBox(width: AppConstants.spaceS),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppConstants.captionSize,
                color: AppConstants.securityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Permission denied error
class PermissionDeniedError extends StatelessWidget {
  final String permissionName;
  final VoidCallback onOpenSettings;

  const PermissionDeniedError({
    Key? key,
    required this.permissionName,
    required this.onOpenSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorDisplay(
      message:
          '$permissionName permission is required to use this feature. Please enable it in your device settings.',
      icon: Icons.block,
      onRetry: onOpenSettings,
      isFullScreen: true,
    );
  }
}
