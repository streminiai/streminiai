// lib/utils/theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// App theme configuration matching the dark WhatsApp-style UI
class AppTheme {
  // Dark Theme (Primary)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.primaryColor,
        surface: AppConstants.surfaceDark,
        background: AppConstants.backgroundDark,
        error: AppConstants.securityColor,
        onPrimary: AppConstants.textPrimary,
        onSecondary: AppConstants.textPrimary,
        onSurface: AppConstants.textPrimary,
        onBackground: AppConstants.textPrimary,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppConstants.backgroundDark,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.surfaceDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppConstants.textPrimary,
          fontSize: AppConstants.titleSize,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppConstants.textPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppConstants.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.overlayBorderRadius),
        ),
      ),
      
      // Input Decoration Theme (for text fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.inputFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: AppConstants.textSecondary,
          fontSize: AppConstants.bodySize,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spaceL,
            vertical: AppConstants.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: AppConstants.bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: TextStyle(
            fontSize: AppConstants.bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppConstants.textPrimary,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.bubbleBorderRadius),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppConstants.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.overlayBorderRadius),
        ),
        titleTextStyle: TextStyle(
          color: AppConstants.textPrimary,
          fontSize: AppConstants.titleSize,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: AppConstants.textSecondary,
          fontSize: AppConstants.bodySize,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.overlayBorderRadius),
          ),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppConstants.dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        // Headlines
        headlineLarge: TextStyle(
          fontSize: AppConstants.headingSize,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppConstants.titleSize,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
        
        // Body Text
        bodyLarge: TextStyle(
          fontSize: AppConstants.bodySize,
          fontWeight: FontWeight.normal,
          color: AppConstants.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.bodySize,
          fontWeight: FontWeight.normal,
          color: AppConstants.textSecondary,
        ),
        
        // Caption
        bodySmall: TextStyle(
          fontSize: AppConstants.captionSize,
          fontWeight: FontWeight.normal,
          color: AppConstants.textSecondary,
        ),
        
        // Labels
        labelLarge: TextStyle(
          fontSize: AppConstants.bodySize,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }
  
  // Custom Text Styles
  static TextStyle get messageUserStyle => TextStyle(
    fontSize: AppConstants.bodySize,
    color: AppConstants.textPrimary,
    height: 1.4,
  );
  
  static TextStyle get messageAiStyle => TextStyle(
    fontSize: AppConstants.bodySize,
    color: AppConstants.textPrimary,
    height: 1.4,
  );
  
  static TextStyle get timestampStyle => TextStyle(
    fontSize: AppConstants.captionSize,
    color: AppConstants.textSecondary,
  );
  
  static TextStyle get featureTitleStyle => TextStyle(
    fontSize: AppConstants.bodySize,
    fontWeight: FontWeight.w600,
    color: AppConstants.textPrimary,
  );
  
  static TextStyle get featureSubtitleStyle => TextStyle(
    fontSize: AppConstants.captionSize,
    color: AppConstants.textSecondary,
  );
}

/// Custom Decorations
class AppDecorations {
  // Chat Bubble Decorations
  static BoxDecoration userBubbleDecoration = BoxDecoration(
    color: AppConstants.userBubbleColor,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppConstants.chatBubbleRadius),
      topRight: Radius.circular(AppConstants.chatBubbleRadius),
      bottomLeft: Radius.circular(AppConstants.chatBubbleRadius),
      bottomRight: Radius.circular(4),
    ),
  );
  
  static BoxDecoration aiBubbleDecoration = BoxDecoration(
    color: AppConstants.aiBubbleColor,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppConstants.chatBubbleRadius),
      topRight: Radius.circular(AppConstants.chatBubbleRadius),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(AppConstants.chatBubbleRadius),
    ),
  );
  
  // Floating Bubble Decoration
  static BoxDecoration floatingBubbleDecoration = BoxDecoration(
    color: AppConstants.primaryColor,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppConstants.primaryColor.withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  // Overlay Window Decoration
  static BoxDecoration overlayDecoration = BoxDecoration(
    color: AppConstants.surfaceDark,
    borderRadius: BorderRadius.circular(AppConstants.overlayBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );
  
  // Feature Card Decoration
  static BoxDecoration featureCardDecoration = BoxDecoration(
    color: AppConstants.cardDark,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppConstants.dividerColor,
      width: 1,
    ),
  );
}

/// Custom Shadows
class AppShadows {
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
