import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Your backend base URL (replace if needed)
  final String _baseUrl =
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  // -------------------------------
  // 1. Scan text content
  // -------------------------------
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

  // -------------------------------
  // 2. GET request
  // -------------------------------
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  // -------------------------------
  // 3. POST request
  // -------------------------------
  Future<dynamic> post(
      String endpoint, Map<String, dynamic> data) async {
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

  // -------------------------------
  // 4. UPLOAD IMAGE (multipart)
  // -------------------------------
  Future<dynamic> uploadImage(String endpoint, File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');

      var request = http.MultipartRequest('POST', uri);

      // Attach image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',       // <-- backend must expect form field "image"
        imageFile.path,
      ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // -------------------------------
  // 5. Unified response handler
  // ----
