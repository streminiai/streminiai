import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // Test backend connection
  Future<bool> testConnection() async {
    try {
      print('🧪 Testing backend connection...');
      final response = await http.get(Uri.parse(_baseUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      print('✅ Backend status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
  
  // Send chat message - FIXED VERSION
  Future<Map<String, dynamic>> sendChatMessage(String message, {List<Map<String, dynamic>>? history}) async {
    print('\n========== CHAT REQUEST START ==========');
    print('🔵 Sending message: $message');
    print('📍 Backend URL: $_baseUrl/chat/message');
    
    try {
      // Build the request
      final url = Uri.parse('$_baseUrl/chat/message');
      print('🌐 Full URL: $url');
      
      // Prepare the body
      final body = {
        'message': message,
        'conversationHistory': history ?? []
      };
      
      final bodyJson = jsonEncode(body);
      print('📦 Request body: $bodyJson');
      
      // Create HTTP client with longer timeout
      final client = http.Client();
      
      try {
        // Make the request with proper headers
        print('⏳ Sending POST request...');
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': 'https://stremini.app', // Add origin header for CORS
          },
          body: bodyJson,
        ).timeout(
          const Duration(seconds: 60), // Increased timeout for AI responses
          onTimeout: () {
            print('⏱️ Request timed out after 60 seconds!');
            throw TimeoutException('The AI is taking too long to respond. Please try again.');
          },
        );
        
        print('📨 Response received!');
        print('📊 Status code: ${response.statusCode}');
        print('📋 Response headers: ${response.headers}');
        print('📄 Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        print('========== CHAT REQUEST END ==========\n');
        
        // Handle the response
        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            
            // Validate response structure
            if (data is! Map<String, dynamic>) {
              throw Exception('Invalid response format from server');
            }
            
            return data;
          } catch (e) {
            print('❌ JSON decode error: $e');
            throw Exception('Failed to parse server response: ${e.toString()}');
          }
        } else if (response.statusCode == 404) {
          throw Exception('Chat endpoint not found. Please check if the backend is properly deployed.');
        } else if (response.statusCode == 500) {
          throw Exception('Server error. The AI backend encountered an issue.');
        } else {
          // Try to parse error
          try {
            final errorData = jsonDecode(response.body);
            throw Exception(errorData['error'] ?? errorData['message'] ?? 'Server error: ${response.statusCode}');
          } catch (e) {
            throw Exception('Server error (${response.statusCode}): ${response.body}');
          }
        }
      } finally {
        client.close();
      }
      
    } on SocketException catch (e) {
      print('❌ SocketException: Network connectivity issue');
      print('   Error code: ${e.osError?.errorCode}');
      print('   Message: ${e.message}');
      print('   Details: $e');
      
      // Provide more specific error messages
      if (e.osError?.errorCode == 7 || e.osError?.errorCode == 8) {
        throw Exception('Cannot reach server. Please check:\n• Your internet connection\n• If you\'re using WiFi, try mobile data\n• VPN settings if applicable');
      } else if (e.osError?.errorCode == 101) {
        throw Exception('Network unreachable. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}\nPlease check your internet connection and try again.');
      }
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: Request took too long');
      print('   Details: $e');
      throw Exception('Request timed out. The server might be overloaded. Please try again.');
    } on FormatException catch (e) {
      print('❌ FormatException: Invalid JSON response');
      print('   Details: $e');
      throw Exception('Received invalid data from server. Please try again.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: HTTP client error');
      print('   Details: $e');
      throw Exception('Connection failed: ${e.message}');
    } on HandshakeException catch (e) {
      print('❌ HandshakeException: SSL/TLS error');
      print('   Details: $e');
      throw Exception('Secure connection failed. Please check your network settings.');
    } catch (e) {
      print('❌ Unexpected error: ${e.runtimeType}');
      print('   Details: $e');
      
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
  
  // Scan text content for threats
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
      throw Exception('Failed to scan content: $e');
    }
  }
  
  // Analyze text (separate endpoint)
  Future<Map<String, dynamic>> analyzeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/security/analyze-text'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 30));
      
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
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Send streaming chat message (SSE)
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to check URL: $e');
    }
  }
  
  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
