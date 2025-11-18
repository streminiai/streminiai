import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Correct backend URL from documentation
  final String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  Future<Map<String, dynamic>> scanContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/scan-content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to scan content: $e');
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }
}
