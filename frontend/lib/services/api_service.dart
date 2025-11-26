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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "⚠️ Empty reply from AI.";
      } else {
        return "❌ Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ Network or decoding error: $e";
    }
  }

  // Security - Scan content for scams/phishing
  Future<SecurityScanResult> scanContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/security/scan-content"),
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
