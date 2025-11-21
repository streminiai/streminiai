import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // Keep URL private - never expose in errors
  static const String _baseUrl = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // Retry configuration for cold starts
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _timeout = Duration(seconds: 45);

  // Generic error messages (no URL exposure)
  static const String _connectionError = 'Unable to connect to server. Please check your internet connection.';
  static const String _serverError = 'Server is temporarily unavailable. Please try again in a moment.';
  static const String _timeoutError = 'Request timed out. The server may be waking up, please try again.';
  static const String _unknownError = 'Something went wrong. Please try again.';

  /// Send chat message with automatic retry for cold starts
  Future<Map<String, dynamic>> sendChatMessage(String message, {List<Map<String, dynamic>>? history}) async {
    print('\n🚀 SENDING MESSAGE: $message');
    
    Exception? lastException;
    
    // Retry loop to handle Cloudflare Worker cold starts
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('📤 Attempt $attempt of $_maxRetries');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/chat/message'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'StreminiApp/1.0',
          },
          body: jsonEncode({
            'message': message,
            'conversationHistory': history ?? []
          }),
        ).timeout(_timeout);
        
        print('📨 Status: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final decoded = jsonDecode(response.body);
            print('✅ Success!');
            return decoded is Map<String, dynamic> ? decoded : {'response': decoded.toString()};
          } catch (e) {
            return {'response': response.body};
          }
        } else if (response.statusCode >= 500) {
          // Server error - might be cold start, retry
          lastException = Exception(_serverError);
          if (attempt < _maxRetries) {
            print('⏳ Server error, retrying in ${_retryDelay.inSeconds}s...');
            await Future.delayed(_retryDelay);
            continue;
          }
        } else if (response.statusCode == 404) {
          throw Exception('Chat service is not available.');
        } else {
          // Try to get error message without exposing internals
          String errorMsg = _unknownError;
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody['error'] != null) {
              errorMsg = _sanitizeError(errorBody['error'].toString());
            }
          } catch (_) {}
          throw Exception(errorMsg);
        }
      } on SocketException catch (e) {
        print('❌ Socket error: $e');
        lastException = Exception(_connectionError);
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on TimeoutException catch (e) {
        print('❌ Timeout: $e');
        lastException = Exception(_timeoutError);
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on http.ClientException catch (e) {
        print('❌ Client error: $e');
        lastException = Exception(_connectionError);
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } catch (e) {
        print('❌ Error: $e');
        final sanitized = _sanitizeError(e.toString());
        lastException = Exception(sanitized);
        
        // Don't retry for non-network errors
        if (!_isRetryableError(e)) {
          throw lastException!;
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      }
    }
    
    // All retries exhausted
    throw lastException ?? Exception(_unknownError);
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      print('🧪 Testing connection...');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      print('✅ Connection test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed');
      return false;
    }
  }

  /// Streaming chat (SSE) with retry
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
        throw Exception(_serverError);
      }
    } catch (e) {
      throw Exception(_sanitizeError(e.toString()));
    }
  }

  /// Security: Scan content with retry
  Future<Map<String, dynamic>> scanContent(String content) async {
    return _postWithRetry(
      '/security/scan-content',
      {'content': content},
    );
  }

  /// Analyze text for security threats
  Future<Map<String, dynamic>> analyzeText(String text) async {
    return _postWithRetry(
      '/text/analyze-text',
      {'text': text},
    );
  }

  /// Upload and analyze image
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
    } on SocketException {
      throw Exception(_connectionError);
    } on TimeoutException {
      throw Exception(_timeoutError);
    } catch (e) {
      throw Exception(_sanitizeError(e.toString()));
    }
  }

  /// Generic POST with retry logic
  Future<Map<String, dynamic>> _postWithRetry(String endpoint, Map<String, dynamic> body) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(_timeout);
        
        return _handleResponse(response);
      } on SocketException {
        lastException = Exception(_connectionError);
      } on TimeoutException {
        lastException = Exception(_timeoutError);
      } catch (e) {
        lastException = Exception(_sanitizeError(e.toString()));
        if (!_isRetryableError(e)) throw lastException;
      }
      
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }
    
    throw lastException ?? Exception(_unknownError);
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'response': response.body};
      }
    } else if (response.statusCode >= 500) {
      throw Exception(_serverError);
    } else {
      String errorMessage = _unknownError;
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = _sanitizeError(errorBody['error'] ?? errorBody['message'] ?? _unknownError);
      } catch (e) {
        // Don't expose raw response
      }
      throw Exception(errorMessage);
    }
  }

  /// Remove any URLs or sensitive info from error messages
  String _sanitizeError(String error) {
    // Remove URLs
    error = error.replaceAll(RegExp(r'https?://[^\s]+'), '[server]');
    // Remove "Exception: " prefix
    error = error.replaceFirst('Exception: ', '');
    // Remove technical details
    error = error.replaceAll(RegExp(r'uri=[^\s,\)]+'), '');
    error = error.replaceAll(RegExp(r'errno\s*=\s*\d+'), '');
    error = error.replaceAll(RegExp(r'OS Error:[^,\)]+'), '');
    
    // If still contains technical jargon, return generic message
    if (error.contains('SocketException') || 
        error.contains('ClientException') ||
        error.contains('host lookup') ||
        error.contains('.workers.dev') ||
        error.contains('.cloudflare')) {
      return _connectionError;
    }
    
    return error.trim().isEmpty ? _unknownError : error.trim();
  }

  /// Check if error is retryable
  bool _isRetryableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socket') ||
           errorStr.contains('timeout') ||
           errorStr.contains('connection') ||
           errorStr.contains('host lookup') ||
           errorStr.contains('network');
  }
}
