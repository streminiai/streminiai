// lib/features/settings_provider.dart
import 'package:flutter/foundation.dart';

class SettingsProvider with ChangeNotifier {
  // Placeholder settings
  bool _isFloatingWidgetEnabled = true;
  String _geminiApiKey = 'YOUR_API_KEY_HERE'; // Stored securely in a real app
  bool _isAccessibilityEnabled = false;

  // Getters
  bool get isFloatingWidgetEnabled => _isFloatingWidgetEnabled;
  String get geminiApiKey => _geminiApiKey;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  
  // Setter for the floating widget
  void toggleFloatingWidget(bool isEnabled) {
    _isFloatingWidgetEnabled = isEnabled;
    notifyListeners();
    // Native bridge call to enable/disable overlay service would go here
  }

  // Setter for the accessibility service status
  void setAccessibilityEnabled(bool isEnabled) {
    _isAccessibilityEnabled = isEnabled;
    notifyListeners();
  }

  // Setter for API Key
  void setGeminiApiKey(String key) {
    _geminiApiKey = key;
    notifyListeners();
    // In a real app, this should be saved to persistent storage (e.g., shared preferences)
  }
  
  // Add other settings as needed (e.g., preferred languages, dark mode)
}
