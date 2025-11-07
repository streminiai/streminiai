import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/chat_message.dart';
import '../models/automation_action.dart';
import '../models/security_scan_result.dart';

class StreminiApiService {
  static final StreminiApiService _instance = StreminiApiService._internal();
  factory StreminiApiService() => _instance;
  StreminiApiService._internal();

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // Chat
  Future<String> sendChatMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    final response = await _post(
      ApiConstants.chatMessage,
      {
        'message': message,
        'conversationHistory': history.map((m) => m.toJson()).toList(),
      },
    );
    return response['response'] as String;
  }

  // Automation
  Future<AutomationAction> parseVoiceCommand(String command) async {
    final response = await _post(
      ApiConstants.automationVoiceCommand,
      {'command': command},
    );
    return AutomationAction.fromJson(response['parsed']);
  }

  // Translation
  Future<String> translateScreen(String content, String language) async {
    final response = await _post(
      ApiConstants.translationTranslateScreen,
      {'content': content, 'targetLanguage': language},
    );
    return response['translatedContent'] as String;
  }

  // Security
  Future<SecurityScanResult> scanContent(String content) async {
    final response = await _post(
      ApiConstants.securityScanContent,
      {'content': content},
    );
    return SecurityScanResult.fromJson(response['analysis']);
  }

  // Keyboard
  Future<String> completeText(String text, String context) async {
    final response = await _post(
      ApiConstants.keyboardComplete,
      {'text': text, 'context': context},
    );
    return response['completion'] as String;
  }

  Future<String> changeTone(String text, String tone) async {
    final response = await _post(
      ApiConstants.keyboardTone,
      {'text': text, 'tone': tone},
    );
    return response['rewritten'] as String;
  }

  Future<String> translateText(String text, String language) async {
    final response = await _post(
      ApiConstants.keyboardTranslate,
      {'text': text, 'targetLanguage': language},
    );
    return response['translation'] as String;
  }

  void dispose() => _client.close();
}
