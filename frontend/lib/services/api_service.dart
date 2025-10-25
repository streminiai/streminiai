import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String endpoint =
      "https://stremini-chatbot-worker.vishwajeetadkine705.workers.dev";
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
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
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final sendMessageProvider =
    FutureProvider.family<String, String>((ref, userMessage) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.sendMessage(userMessage);
});
