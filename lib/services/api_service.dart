import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // SUPER SIMPLE: Just send a message and get a response
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
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 60));
      
      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
      
    } on SocketException catch (e) {
      print('❌ No internet: $e');
      throw Exception('No internet connection. Check your WiFi/data.');
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      throw Exception('Request timed out. Server is slow.');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error: $e');
    }
  }
  
  // Test connection
  Future<bool> testConnection() async {
    try {
      print('🧪 Testing connection...');
      final response = await http.get(Uri.parse(_baseUrl)).timeout(
        const Duration(seconds: 10),
      );
      print('✅ Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test failed: $e');
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
      
      final streamedResponse = await request.send();
      
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
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
        return response.body;
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
