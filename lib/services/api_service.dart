import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // FIXED: Better error handling and timeout management
  Future<Map<String, dynamic>> sendChatMessage(String message, {List<Map<String, dynamic>>? history}) async {
    print('\n🚀 SENDING MESSAGE');
    print('📝 Message: $message');
    
    try {
      final url = Uri.parse('$_baseUrl/chat/message');
      
      final body = jsonEncode({
        'message': message,
        'conversationHistory': history ?? []
      });
      
      print('📍 URL: $url');
      print('📦 Body: $body');
      print('⏳ Sending...');
      
      // FIXED: Better timeout and headers
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'StreminiApp/1.0',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request took too long. Please try again.');
        },
      );
      
      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(response.body);
          return decoded is Map<String, dynamic> ? decoded : {'response': decoded.toString()};
        } catch (e) {
          print('⚠️ JSON decode error: $e');
          // If not JSON, wrap the response
          return {'response': response.body};
        }
      } else if (response.statusCode >= 500) {
        throw Exception('Server error (${response.statusCode}). Please try again later.');
      } else if (response.statusCode == 404) {
        throw Exception('Chat endpoint not found. Check backend configuration.');
      } else {
        throw Exception('Request failed (${response.statusCode}): ${response.body}');
      }
      
    } on SocketException catch (e) {
      print('❌ Socket error: $e');
      throw Exception('Cannot reach server. Check your internet connection.');
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      throw Exception('Request timed out. Server might be slow.');
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      throw Exception('Invalid response from server.');
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (e.toString().contains('Connection refused')) {
        throw Exception('Server refused connection. Backend might be down.');
      } else if (e.toString().contains('Failed host lookup')) {
        throw Exception('Cannot find server. Check your internet connection.');
      }
      throw Exception('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
  
  // FIXED: More robust connection test
  Future<bool> testConnection() async {
    try {
      print('🧪 Testing connection to: $_baseUrl');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Connection test status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      return response.statusCode == 200;
    } on SocketException catch (e) {
      print('❌ Socket error in test: $e');
      return false;
    } on TimeoutException catch (e) {
      print('❌ Timeout in test: $e');
      return false;
    } catch (e) {
      print('❌ Test error: $e');
      return false;
    }
  }
  
  // Streaming chat (SSE)
  Stream<String> sendStreamingChatMessage(String message, {List<Map<String, dynamic>>? history}) async* {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode({
        'message': message,
        'conversationHistory': history ?? []
      });
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data.trim().isNotEmpty && data != '[DONE]') {
                try {
                  final json = jsonDecode(data);
                  if (json['text'] != null) {
                    yield json['text'];
                  }
                } catch (e) {
                  continue;
                }
              }
            }
          }
        }
      } else {
        throw Exception('Streaming failed with status ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Streaming failed: $e');
    }
  }
  
  // Security: Scan content
  Future<Map<String, dynamic>> scanContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/scan-content'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'content': content}),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Scan failed: $e');
    }
  }

  // Analyze text for security threats
  Future<Map<String, dynamic>> analyzeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/text/analyze-text'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Text analysis failed: $e');
    }
  }

  // Upload and analyze image
  Future<Map<String, dynamic>> uploadImage(String endpoint, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$endpoint'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
  
  // Generic response handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'response': response.body};
      }
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['error'] ?? errorBody['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}
