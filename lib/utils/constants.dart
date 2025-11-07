// lib/utils/constants.dart

import 'package:flutter/material.dart';

/// App-wide constants for Stremini AI
class AppConstants {
  // App Info
  static const String appName = 'Stremini AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your AI Assistant Everywhere';

  // Overlay Settings (Floating Bubble)
  static const double floatingBubbleSize = 56.0;
  static const double floatingBubbleExpandedWidth = 320.0;
  static const double floatingBubbleExpandedHeight = 500.0;
  static const double overlayBorderRadius = 24.0;
  static const double bubbleBorderRadius = 28.0;
  
  // Chat UI Settings (Based on your WhatsApp-style screenshot)
  static const double chatBubbleRadius = 12.0;
  static const double chatInputHeight = 56.0;
  static const double messageBubbleMaxWidth = 0.75; // 75% of screen
  static const EdgeInsets chatPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  
  // Colors - Dark Theme (matching your screenshot)
  static const Color primaryColor = Color(0xFF00BFA6); // Teal/Cyan accent
  static const Color backgroundDark = Color(0xFF0D1117); // Very dark background
  static const Color surfaceDark = Color(0xFF1C1F26); // Dark surface
  static const Color cardDark = Color(0xFF22262E); // Card background
  static const Color userBubbleColor = Color(0xFF005C4B); // User message dark green
  static const Color aiBubbleColor = Color(0xFF1C1F26); // AI message dark gray
  static const Color inputFieldColor = Color(0xFF22262E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8E93);
  static const Color dividerColor = Color(0xFF2C3038);
  
  // Feature Colors
  static const Color chatColor = Color(0xFF00BFA6);
  static const Color translationColor = Color(0xFF64B5F6);
  static const Color securityColor = Color(0xFFFF6B6B);
  static const Color keyboardColor = Color(0xFFFFD700);
  static const Color automationColor = Color(0xFFAB47BC);
  
  // Typography
  static const double headingSize = 24.0;
  static const double titleSize = 18.0;
  static const double bodySize = 14.0;
  static const double captionSize = 12.0;
  
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  
  // Chat Settings
  static const int maxChatHistory = 50;
  static const int maxMessageLength = 2000;
  static const Duration typingAnimationDuration = Duration(milliseconds: 800);
  static const Duration messageAnimationDuration = Duration(milliseconds: 200);
  
  // Translation Settings
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Marathi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
  ];
  
  static const Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Marathi': 'mr',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Chinese': 'zh',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Arabic': 'ar',
  };
  
  // Security Settings
  static const List<String> threatTypes = [
    'Phishing',
    'Scam',
    'Malware',
    'Spam',
    'Suspicious Link',
  ];
  
  // Keyboard Tone Options
  static const List<String> toneOptions = [
    'Professional',
    'Casual',
    'Formal',
    'Friendly',
    'Brief',
    'Detailed',
  ];
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(seconds: 60);
  
  // Permissions
  static const List<String> requiredPermissions = [
    'Overlay',
    'Accessibility',
    'Microphone',
  ];
}

/// Icon paths
class AppIcons {
  static const String chat = 'assets/icons/chat.svg';
  static const String translate = 'assets/icons/translate.svg';
  static const String security = 'assets/icons/security.svg';
  static const String keyboard = 'assets/icons/keyboard.svg';
  static const String automation = 'assets/icons/automation.svg';
  static const String mic = 'assets/icons/mic.svg';
  static const String send = 'assets/icons/send.svg';
  static const String settings = 'assets/icons/settings.svg';
}

/// Animation curves
class AppCurves {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
}
