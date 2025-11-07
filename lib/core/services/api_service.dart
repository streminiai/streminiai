import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // Helper method for POST requests
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // Helper method for GET requests
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // ========== CHAT ENDPOINTS ==========
  
  Future<String> sendChatMessage(String message, List<Map<String, String>> history) async {
    final response = await _post(ApiConstants.chatMessage, {
      'message': message,
      'conversationHistory': history,
    });
    return response['response'] as String;
  }

  Future<List<String>> getChatSuggestions() async {
    final response = await _get(ApiConstants.chatSuggestions);
    final suggestions = response['suggestions'] as List<dynamic>;
    return suggestions.map((e) => e.toString()).toList();
  }

  // ========== KEYBOARD ENDPOINTS ==========
  
  Future<String> completeText(String text, {String context = ''}) async {
    final response = await _post(ApiConstants.keyboardComplete, {
      'text': text,
      'context': context,
    });
    return response['completion'] as String;
  }

  Future<String> changeTone(String text, String tone) async {
    final response = await _post(ApiConstants.keyboardTone, {
      'text': text,
      'tone': tone,
    });
    return response['rewritten'] as String;
  }

  Future<String> translateText(String text, String targetLanguage) async {
    final response = await _post(ApiConstants.keyboardTranslate, {
      'text': text,
      'targetLanguage': targetLanguage,
    });
    return response['translation'] as String;
  }

  // ========== AUTOMATION ENDPOINTS ==========
  
  Future<Map<String, dynamic>> parseVoiceCommand(String command) async {
    final response = await _post(ApiConstants.automationVoiceCommand, {
      'command': command,
    });
    return response['parsed'] as Map<String, dynamic>;
  }

  // ========== SECURITY ENDPOINTS ==========
  
  Future<Map<String, dynamic>> scanContent(String content) async {
    final response = await _post(ApiConstants.securityScanContent, {
      'content': content,
    });
    return response['analysis'] as Map<String, dynamic>;
  }

  Future<bool> checkUrl(String url) async {
    final response = await _post(ApiConstants.securityCheckUrl, {
      'url': url,
    });
    return response['isSafe'] as bool? ?? true;
  }

  // ========== TRANSLATION ENDPOINTS ==========
  
  Future<String> translateScreen(String content, String targetLanguage) async {
    final response = await _post(ApiConstants.translationTranslateScreen, {
      'content': content,
      'targetLanguage': targetLanguage,
    });
    return response['translatedContent'] as String;
  }
}
