// lib/utils/extensions.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format as time (e.g., "10:30 AM")
  String toTimeString() {
    return DateFormat('hh:mm a').format(this);
  }
  
  /// Format as date (e.g., "Nov 7, 2025")
  String toDateString() {
    return DateFormat('MMM d, yyyy').format(this);
  }
  
  /// Format as chat timestamp
  /// Today: "10:30 AM"
  /// Yesterday: "Yesterday"
  /// This week: "Monday"
  /// Older: "Nov 7"
  String toChatTimestamp() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(year, month, day);
    
    if (messageDate == today) {
      return toTimeString();
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat('EEEE').format(this);
    } else {
      return DateFormat('MMM d').format(this);
    }
  }
  
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
}

/// Extension methods for String
extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if string is not empty
  bool get isNotNullOrEmpty => isNotEmpty;
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Truncate string to max length with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
  
  /// Remove extra whitespace
  String get removeExtraSpaces {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Check if string is a valid URL
  bool get isValidUrl {
    final urlPattern = RegExp(
      r'^(http|https):\/\/([\w-]+\.)+[\w-]+(\/[\w- .\/?%&=]*)?$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(this);
  }
  
  /// Check if string contains only emojis
  bool get isOnlyEmojis {
    final emojiPattern = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );
    return emojiPattern.hasMatch(this);
  }
}

/// Extension methods for BuildContext
extension ContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Get theme
  ThemeData get theme => Theme.of(this);
  
  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Show loading dialog
  void showLoadingDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
  
  /// Hide dialog
  void hideDialog() {
    Navigator.of(this).pop();
  }
  
  /// Navigate to screen
  void navigateTo(Widget screen) {
    Navigator.of(this).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  /// Navigate and replace
  void navigateAndReplace(Widget screen) {
    Navigator.of(this).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  /// Go back
  void goBack() {
    Navigator.of(this).pop();
  }
}

/// Extension methods for Color
extension ColorExtensions on Color {
  /// Get contrasting text color (black or white)
  Color get contrastingTextColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Lighten color by percentage
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Darken color by percentage
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Extension methods for List
extension ListExtensions<T> on List<T> {
  /// Get last N items
  List<T> lastN(int n) {
    if (n >= length) return this;
    return sublist(length - n);
  }
  
  /// Get first N items
  List<T> firstN(int n) {
    if (n >= length) return this;
    return sublist(0, n);
  }
  
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if list is not empty
  bool get isNotNullOrEmpty => isNotEmpty;
}
