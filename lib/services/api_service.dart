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
  
  // Send chat message - WITH DEBUGGING
  Future<Map<String, dynamic>> sendChatMessage(String message, {List<Map<String, dynamic>>? history}) async {
    print('🔵 Starting chat request...');
    print('📍 URL: $_baseUrl/chat/message');
    print('💬 Message: $message');
    
    try {
      final uri = Uri.parse('$_baseUrl/chat/message');
      print('🌐 Parsed URI: $uri');
      
      final requestBody = jsonEncode({
        'message': message,
        'conversationHistory': history ?? []
      });
      print('📦 Request body: $requestBody');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Request timed out after 30 seconds');
          throw Exception('Request timed out. Please try again.');
        },
      );
      
      print('✅ Response received!');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      return _handleResponse(response);
      
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      print('🔍 This usually means DNS resolution failed or no internet');
      throw Exception('Cannot connect to server. Please check your internet connection.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Network error. Please try again.');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Invalid server response format.');
    } catch (e) {
      print('❌ Unknown error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (e.toString().contains('timed out')) {
        throw Exception('Request timed out. Please try again.');
      } else if (e.toString().contains('Failed host lookup')) {
        throw Exception('Cannot reach server. Check your internet connection.');
      }
      
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }
  
  // Send streaming chat message (SSE)
  Stream<String> sendStreamingChatMessage(String message, {List<Map<String, dynamic>>? history}) async* {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'message': message,  // Correct: backend expects 'message'
        'conversationHistory': history ?? []  // Correct: backend expects 'conversationHistory'
      });
      
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // Parse SSE format: "data: {json}\n\n"
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6); // Remove "data: " prefix
              if (data.trim().isNotEmpty && data != '[DONE]') {
                try {
                  final json = jsonDecode(data);
                  if (json['text'] != null) {
                    yield json['text'];
                  }
                } catch (e) {
                  // Skip invalid JSON chunks
                  continue;
                }
              }
            }
          }
        }
      } else {
        throw Exception('Stream request failed with status: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to stream message: $e');
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
