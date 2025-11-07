// lib/services/stremini_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:stremini_chatbot/models/automation_action.dart';
import 'package:stremini_chatbot/models/security_scan_result.dart';
import 'package:stremini_chatbot/features/settings_provider.dart'; // To access the API Key

class StreminiApiService {
  // Use the Cloudflare Worker URL provided by the user
  final String _baseUrl = 'https://ai-keyboard-backend.vishwajeetadkine705.workers.dev';
  final SettingsProvider _settingsProvider;
  
  // The service needs the SettingsProvider to retrieve the API Key dynamically
  StreminiApiService({required SettingsProvider settingsProvider}) : _settingsProvider = settingsProvider;

  Map<String, String> _getHeaders() {
    // Get the API key from the provider
    final apiKey = _settingsProvider.geminiApiKey; 
    return {
      'Content-Type': 'application/json',
      // Assuming the backend expects the API key in an Authorization header
      'Authorization': 'Bearer $apiKey',
    };
  }

  // --- 1. Chat Endpoints ---

  /// Simulates a streaming response for chat, as Flutter's standard `http` 
  /// package doesn't easily handle true Server-Sent Events (SSE) or chunked responses.
  /// For production, `HttpClient` or a dedicated SSE library would be used.
  Stream<String> streamChatMessage(String message) async* {
    const endpoint = '/chat/stream';
    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        // Assume the backend returns a full string response which we then split
        // to simulate a stream effect for the UI demonstration.
        final fullResponse = jsonDecode(response.body)['response'] as String;
        
        // Simulate streaming by yielding chunks
        final words = fullResponse.split(' ');
        for (final word in words) {
          await Future.delayed(const Duration(milliseconds: 50));
          yield '$word ';
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('API Error (${response.statusCode}): ${errorBody['error']}');
      }
    } catch (e) {
      debugPrint('Chat API Stream Error: $e');
      throw Exception('Network or API failure: $e');
    }
  }


  // --- 2. Automation Endpoint ---

  /// Parses a voice command string into an executable action model.
  Future<AutomationAction> parseVoiceCommand(String command) async {
    const endpoint = '/automation/voice-command';
    final uri = Uri.parse('$_baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode({'command': command}),
    );

    if (response.statusCode == 200) {
      // Assuming the backend returns an object that matches AutomationAction.
      return AutomationAction.fromJson(jsonDecode(response.body));
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Automation API Error (${response.statusCode}): ${errorBody['error']}');
    }
  }


  // --- 3. Translation Endpoint ---

  /// Translates the full screen content to the target language.
  Future<String> translateScreen({required String content, required String targetLang}) async {
    const endpoint = '/translation/translate-screen';
    final uri = Uri.parse('$_baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode({
        'content': content,
        'targetLang': targetLang,
      }),
    );

    if (response.statusCode == 200) {
      // Assuming the backend returns {'translatedText': '...'}
      return jsonDecode(response.body)['translatedText'] as String;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Translation API Error (${response.statusCode}): ${errorBody['error']}');
    }
  }


  // --- 4. Security Endpoints ---

  /// Scans generic text content for threats.
  Future<SecurityScanResult> scanContent(String content) async {
    const endpoint = '/security/scan-content';
    final uri = Uri.parse('$_baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return SecurityScanResult.fromJson(jsonDecode(response.body));
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Scan Content API Error (${response.statusCode}): ${errorBody['error']}');
    }
  }

  /// Checks a specific URL for safety.
  Future<SecurityScanResult> checkUrl(String url) async {
    const endpoint = '/security/check-url';
    final uri = Uri.parse('$_baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode == 200) {
      return SecurityScanResult.fromJson(jsonDecode(response.body));
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Check URL API Error (${response.statusCode}): ${errorBody['error']}');
    }
  }

  
  // --- 5. Keyboard Endpoints (Simplified) ---

  /// Generic handler for keyboard modifications (complete, tone, translate)
  Future<String> _keyboardModify(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Assuming the backend returns {'modifiedText': '...'}
      return jsonDecode(response.body)['modifiedText'] as String;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Keyboard API Error (${response.statusCode}): ${errorBody['error']}');
    }
  }
  
  Future<String> completeText(String currentText) => 
      _keyboardModify('/keyboard/complete', {'text': currentText});

  Future<String> changeTextTone(String text, String newTone) => 
      _keyboardModify('/keyboard/tone', {'text': text, 'tone': newTone});
      
  Future<String> translateKeyboardText(String text, String targetLang) => 
      _keyboardModify('/keyboard/translate', {'text': text, 'targetLang': targetLang});

}
