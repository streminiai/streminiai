class ApiConstants {
  // Your Cloudflare Worker URL
  static const String baseUrl = 'https://ai-keyboard-backend.vishwajeetadkine705.workers.dev';
  
  // Endpoints
  static const String chatMessage = '/chat/message';
  static const String chatStream = '/chat/stream';
  static const String chatSuggestions = '/chat/suggestions';
  
  static const String keyboardComplete = '/keyboard/complete';
  static const String keyboardTone = '/keyboard/tone';
  static const String keyboardTranslate = '/keyboard/translate';
  
  static const String automationVoiceCommand = '/automation/voice-command';
  
  static const String securityScanContent = '/security/scan-content';
  static const String securityCheckUrl = '/security/check-url';
  
  static const String translationTranslateScreen = '/translation/translate-screen';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
