// lib/widgets/floating_widget/feature_menu.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';

/// Feature selection menu for floating widget
class FeatureMenu extends StatelessWidget {
  final Function(String) onFeatureSelected;
  final VoidCallback? onClose;

  const FeatureMenu({
    Key? key,
    required this.onFeatureSelected,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.overlayDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),

          // Feature Grid
          Expanded(
            child: _buildFeatureGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          SizedBox(width: AppConstants.spaceM),
          Text(
            'Choose a Feature',
            style: TextStyle(
              fontSize: AppConstants.titleSize,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          Spacer(),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close),
              color: AppConstants.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'id': 'chat',
        'name': 'AI Chat',
        'description': 'Chat with AI assistant',
        'icon': Icons.chat_bubble_outline,
        'color': AppConstants.chatColor,
      },
      {
        'id': 'translation',
        'name': 'Translate',
        'description': 'Translate screen content',
        'icon': Icons.translate,
        'color': AppConstants.translationColor,
      },
      {
        'id': 'security',
        'name': 'Security Scan',
        'description': 'Check for scams & threats',
        'icon': Icons.security,
        'color': AppConstants.securityColor,
      },
      {
        'id': 'keyboard',
        'name': 'AI Keyboard',
        'description': 'Smart text suggestions',
        'icon': Icons.keyboard,
        'color': AppConstants.keyboardColor,
      },
      {
        'id': 'automation',
        'name': 'Voice Commands',
        'description': 'Control with your voice',
        'icon': Icons.mic,
        'color': AppConstants.automationColor,
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.all(AppConstants.spaceM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: AppConstants.spaceM,
        mainAxisSpacing: AppConstants.spaceM,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureCard(
          name: feature['name'] as String,
          description: feature['description'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          onTap: () {
            AppHelpers.hapticFeedback();
            onFeatureSelected(feature['id'] as String);
          },
        );
      },
    );
  }
}

/// Individual feature card
class FeatureCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.dividerColor,
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(AppConstants.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              
              SizedBox(height: AppConstants.spaceM),
              
              // Name
              Text(
                name,
                style: AppTheme.featureTitleStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4),
              
              // Description
              Text(
                description,
                style: AppTheme.featureSubtitleStyle,
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

/// Compact feature list (alternative layout)
class CompactFeatureList extends StatelessWidget {
  final Function(String) onFeatureSelected;

  const CompactFeatureList({
    Key? key,
    required this.onFeatureSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'id': 'chat',
        'name': 'AI Chat',
        'icon': Icons.chat_bubble_outline,
        'color': AppConstants.chatColor,
      },
      {
        'id': 'translation',
        'name': 'Translate',
        'icon': Icons.translate,
        'color': AppConstants.translationColor,
      },
      {
        'id': 'security',
        'name': 'Security',
        'icon': Icons.security,
        'color': AppConstants.securityColor,
      },
      {
        'id': 'keyboard',
        'name': 'Keyboard',
        'icon': Icons.keyboard,
        'color': AppConstants.keyboardColor,
      },
      {
        'id': 'automation',
        'name': 'Voice',
        'icon': Icons.mic,
        'color': AppConstants.automationColor,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spaceM),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return CompactFeatureItem(
          name: feature['name'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          onTap: () {
            AppHelpers.hapticFeedback();
            onFeatureSelected(feature['id'] as String);
          },
        );
      },
    );
  }
}

/// Compact feature list item
class CompactFeatureItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CompactFeatureItem({
    Key? key,
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spaceS),
      child: Material(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spaceM),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                
                SizedBox(width: AppConstants.spaceM),
                
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: AppConstants.bodySize,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
