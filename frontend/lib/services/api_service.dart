import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  // Chat endpoints
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat/message"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response structures
        if (data is Map) {
          // Check for 'reply' field first
          if (data.containsKey('reply')) {
            return data['reply'] as String? ?? "⚠️ Empty reply from AI.";
          }
          // Check for 'response' field
          if (data.containsKey('response')) {
            return data['response'] as String? ?? "⚠️ Empty reply from AI.";
          }
          // Check for 'message' field
          if (data.containsKey('message')) {
            return data['message'] as String? ?? "⚠️ Empty reply from AI.";
          }
          // If data is directly a string
          return data.toString();
        } else if (data is String) {
          return data;
        }
        
        return "⚠️ Unexpected response format from AI.";
      } else if (response.statusCode == 400) {
        return "❌ Bad request: Please check your message format.";
      } else if (response.statusCode == 500) {
        return "❌ Server error: The AI service is currently unavailable.";
      } else {
        return "❌ Server error: ${response.statusCode}";
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        return "⚠️ Network error: Please check your internet connection.";
      }
      return "⚠️ Error: $e";
    }
  }

  // Chat streaming endpoint (for future use)
  Stream<String> streamMessage(String userMessage) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse("$baseUrl/chat/stream"),
      );
      request.headers.addAll({
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
      });
      request.body = jsonEncode({"message": userMessage});

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // Parse SSE format: data: {...}
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              if (jsonStr.trim().isNotEmpty && jsonStr != '[DONE]') {
                try {
                  final data = jsonDecode(jsonStr);
                  if (data is Map && data.containsKey('token')) {
                    yield data['token'] as String;
                  }
                } catch (_) {
                  // Skip invalid JSON
                }
              }
            }
          }
        }
      } else {
        yield "❌ Server error: ${streamedResponse.statusCode}";
      }
    } catch (e) {
      yield "⚠️ Streaming error: $e";
    }
  }

  // Security - Scan content for scams/phishing
  Future<SecurityScanResult> scanContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/security/scan-content"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"content": content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SecurityScanResult.fromJson(data);
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Automation - Parse voice commands
  Future<VoiceCommandResult> parseVoiceCommand(String command) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/automation/voice-command"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"command": command}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VoiceCommandResult.fromJson(data);
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Translation - Translate screen content
  Future<String> translateScreen(String content, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/translation/translate-screen"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "content": content,
          "targetLanguage": targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["translatedContent"] ?? "";
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Keyboard - Text completion
  Future<String> completeText(String incompleteText) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/keyboard/complete"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"text": incompleteText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["completion"] ?? "";
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Keyboard - Rewrite text in tone
  Future<String> rewriteInTone(String text, String tone) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/keyboard/tone"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"text": text, "tone": tone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["rewritten"] ?? "";
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Keyboard - Translate text
  Future<String> translateText(String text, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/keyboard/translate"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"text": text, "targetLanguage": targetLanguage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["translation"] ?? "";
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // Health check endpoint
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server returned ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "status": "error",
        "message": e.toString(),
      };
    }
  }
}

// Models
class SecurityScanResult {
  final bool isSafe;
  final String riskLevel; // "safe", "warning", "danger"
  final List<String> tags;
  final String analysis;

  SecurityScanResult({
    required this.isSafe,
    required this.riskLevel,
    required this.tags,
    required this.analysis,
  });

  factory SecurityScanResult.fromJson(Map<String, dynamic> json) {
    return SecurityScanResult(
      isSafe: json['isSafe'] ?? true,
      riskLevel: json['riskLevel'] ?? 'safe',
      tags: List<String>.from(json['tags'] ?? []),
      analysis: json['analysis'] ?? '',
    );
  }
}

class VoiceCommandResult {
  final String action;
  final Map<String, dynamic> parameters;

  VoiceCommandResult({
    required this.action,
    required this.parameters,
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResult(
      action: json['action'] ?? '',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
