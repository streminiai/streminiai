// lib/utils/helpers.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// Helper functions used throughout the app
class AppHelpers {
  /// Generate unique ID
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '$timestamp$random';
  }
  
  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
  
  /// Haptic feedback
  static void hapticFeedback({bool light = true}) {
    if (light) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }
  
  /// Vibrate device
  static void vibrate() {
    HapticFeedback.vibrate();
  }
  
  /// Format file size (bytes to KB/MB/GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Check if URL is safe (basic validation)
  static bool isUrlSafe(String url) {
    // Basic checks
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    
    // Check for common suspicious patterns
    final suspiciousPatterns = [
      'bit.ly',
      'tinyurl',
      'goo.gl',
      't.co',
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (url.contains(pattern)) return false;
    }
    
    return true;
  }
  
  /// Extract domain from URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
  
  /// Check if text contains suspicious content
  static bool containsSuspiciousContent(String text) {
    final lowerText = text.toLowerCase();
    
    for (final keyword in AppConstants.scamKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get color for feature
  static Color getFeatureColor(String feature) {
    switch (feature.toLowerCase()) {
      case 'chat':
        return AppConstants.chatColor;
      case 'translation':
      case 'translate':
        return AppConstants.translationColor;
      case 'security':
      case 'scan':
        return AppConstants.securityColor;
      case 'keyboard':
        return AppConstants.keyboardColor;
      case 'automation':
      case 'voice':
        return AppConstants.automationColor;
      default:
        return AppConstants.primaryColor;
    }
  }
  
  /// Get icon for feature
  static IconData getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'translation':
      case 'translate':
        return Icons.translate;
      case 'security':
      case 'scan':
        return Icons.security;
      case 'keyboard':
        return Icons.keyboard;
      case 'automation':
      case 'voice':
        return Icons.mic;
      default:
        return Icons.star;
    }
  }
  
  /// Validate message length
  static String? validateMessage(String message) {
    if (message.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (message.length > AppConstants.maxMessageLength) {
      return 'Message too long (max ${AppConstants.maxMessageLength} characters)';
    }
    
    return null;
  }
  
  /// Format duration (e.g., "2h 30m", "45s")
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  /// Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  
  /// Calculate reading time (words per minute)
  static String estimateReadingTime(String text, {int wpm = 200}) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / wpm).ceil();
    
    if (minutes < 1) return '< 1 min read';
    if (minutes == 1) return '1 min read';
    return '$minutes min read';
  }
  
  /// Truncate text with word boundary
  static String truncateWithWordBoundary(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    final truncated = text.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    
    if (lastSpace > 0) {
      return '${truncated.substring(0, lastSpace)}...';
    }
    
    return '$truncated...';
  }
  
  /// Get language name from code
  static String getLanguageName(String code) {
    return AppConstants.languageCodes.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => MapEntry('Unknown', code),
        )
        .key;
  }
  
  /// Get language code from name
  static String getLanguageCode(String name) {
    return AppConstants.languageCodes[name] ?? 'en';
  }
  
  /// Check if device is in dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Debounce function calls
  static void debounce(
    Function() function, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Future.delayed(delay, function);
  }
  
  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color color1, Color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    
    final lighter = max(luminance1, luminance2);
    final darker = min(luminance1, luminance2);
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Check if text is likely spam
  static bool isLikelySpam(String text) {
    final lowerText = text.toLowerCase();
    
    // Check for excessive caps
    final capsCount = text.split('').where((c) => c == c.toUpperCase()).length;
    if (capsCount > text.length * 0.5 && text.length > 10) return true;
    
    // Check for excessive punctuation
    final punctuationCount = RegExp(r'[!?.]').allMatches(text).length;
    if (punctuationCount > 5) return true;
    
    // Check for spam keywords
    final spamKeywords = [
      'click here',
      'free money',
      'prize',
      'winner',
      'congratulations',
      'act now',
      'limited time',
      'verify account',
    ];
    
    for (final keyword in spamKeywords) {
      if (lowerText.contains(keyword)) return true;
    }
    
    return false;
  }
}
