// lib/widgets/chat/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/extensions.dart';
import '../../utils/helpers.dart';

/// Chat message bubble matching WhatsApp style
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showTimestamp = true,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onLongPress: onLongPress ?? () => _showMessageOptions(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: AppConstants.spaceXS,
        ),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // AI Avatar (left side for AI messages)
            if (!isUser) ...[
              _buildAvatar(isUser: false),
              SizedBox(width: AppConstants.spaceS),
            ],

            // Message Content
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * AppConstants.messageBubbleMaxWidth,
                ),
                decoration: isUser
                    ? AppDecorations.userBubbleDecoration
                    : AppDecorations.aiBubbleDecoration,
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Text
                    SelectableText(
                      message.content,
                      style: isUser
                          ? AppTheme.messageUserStyle
                          : AppTheme.messageAiStyle,
                    ),

                    // Timestamp
                    if (showTimestamp) ...[
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            message.timestamp.toChatTimestamp(),
                            style: AppTheme.timestampStyle.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          if (isUser) ...[
                            SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: AppConstants.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // User Avatar (right side for user messages)
            if (isUser) ...[
              SizedBox(width: AppConstants.spaceS),
              _buildAvatar(isUser: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? AppConstants.primaryColor
            : AppConstants.cardDark,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser
            ? AppConstants.textPrimary
            : AppConstants.primaryColor,
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    AppHelpers.hapticFeedback();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.overlayBorderRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: AppConstants.spaceM),

            // Copy option
            ListTile(
              leading: Icon(
                Icons.copy,
                color: AppConstants.textPrimary,
              ),
              title: Text(
                'Copy Message',
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              onTap: () {
                AppHelpers.copyToClipboard(message.content);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message copied'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppConstants.cardDark,
                  ),
                );
              },
            ),

            // Select option
            ListTile(
              leading: Icon(
                Icons.select_all,
                color: AppConstants.textPrimary,
              ),
              title: Text(
                'Select Text',
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // Text is already selectable in SelectableText widget
              },
            ),

            SizedBox(height: AppConstants.spaceS),
          ],
        ),
      ),
    );
  }
}

/// Compact message bubble (for history/suggestions)
class CompactMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final VoidCallback? onTap;

  const CompactMessageBubble({
    Key? key,
    required this.message,
    this.isUser = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: AppConstants.spaceXS,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppConstants.userBubbleColor.withOpacity(0.5)
              : AppConstants.aiBubbleColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.chatBubbleRadius),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: AppConstants.captionSize,
            color: AppConstants.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Date separator in chat
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppConstants.spaceM),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getDateText(),
          style: TextStyle(
            fontSize: AppConstants.captionSize,
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getDateText() {
    if (date.isToday) return 'Today';
    if (date.isYesterday) return 'Yesterday';
    return date.toDateString();
  }
}
