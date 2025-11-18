import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  // Scan text content for threats
  Future<Map<String, dynamic>> scanContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/scan-content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to scan content: $e');
    }
  }

  // Analyze text (separate endpoint)
  Future<Map<String, dynamic>> analyzeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/analyze-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to analyze text: $e');
    }
  }

  // Upload and analyze image
  Future<Map<String, dynamic>> uploadImage(String endpoint, File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Send chat message
  Future<Map<String, dynamic>> sendChatMessage(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'conversationHistory': history ?? []
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Check URL safety
  Future<Map<String, dynamic>> checkUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/check-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to check URL: $e');
    }
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  // Response handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['error'] ?? errorBody['message'] ?? errorMessage;
      } catch (e) {
        // If error response is not JSON, use the raw body
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}
