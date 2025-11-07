// lib/widgets/common/permission_card.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// Permission card for onboarding
class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback? onTap;
  final Color? accentColor;

  const PermissionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.isGranted = false,
    this.onTap,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppConstants.primaryColor;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(AppConstants.overlayBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spaceM),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              
              SizedBox(width: AppConstants.spaceM),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppConstants.bodySize,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppConstants.captionSize,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: AppConstants.spaceS),
              
              // Status indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green.withOpacity(0.1)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.arrow_forward,
                      size: 16,
                      color: isGranted ? Colors.green : color,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isGranted ? 'Granted' : 'Grant',
                      style: TextStyle(
                        fontSize: AppConstants.captionSize,
                        fontWeight: FontWeight.w600,
                        color: isGranted ? Colors.green : color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact permission item
class PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isGranted;
  final VoidCallback? onTap;

  const PermissionItem({
    Key? key,
    required this.icon,
    required this.title,
    this.isGranted = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isGranted ? Colors.green : AppConstants.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppConstants.textPrimary,
          fontSize: AppConstants.bodySize,
        ),
      ),
      trailing: Icon(
        isGranted ? Icons.check_circle : Icons.circle_outlined,
        color: isGranted ? Colors.green : AppConstants.textSecondary,
      ),
      onTap: isGranted ? null : onTap,
    );
  }
}

/// Permission status badge
class PermissionBadge extends StatelessWidget {
  final bool isGranted;

  const PermissionBadge({
    Key? key,
    required this.isGranted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isGranted
            ? Colors.green.withOpacity(0.1)
            : AppConstants.securityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.3)
              : AppConstants.securityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isGranted ? Colors.green : AppConstants.securityColor,
          ),
          SizedBox(width: 4),
          Text(
            isGranted ? 'Granted' : 'Required',
            style: TextStyle(
              fontSize: AppConstants.captionSize,
              fontWeight: FontWeight.w600,
              color: isGranted ? Colors.green : AppConstants.securityColor,
            ),
          ),
        ],
      ),
    );
  }
}
