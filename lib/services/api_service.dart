import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  static const int _maxRetries = 2; // Reduced from 3
  static const Duration _retryDelay = Duration(seconds: 1); // Reduced from 2
  static const Duration _timeout = Duration(seconds: 15); // Reduced from 45

  // Improved error messages
  static const String _connectionError =
      'No internet connection. Please check and try again.';
  static const String _serverError =
      'Server is busy. Please try again in a moment.';
  static const String _timeoutError =
      'Request timed out. Please try again.';
  static const String _unknownError = 'Something went wrong. Please try again.';

  /// Send chat message with retry and better error handling
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    Exception? lastError;
    int attempts = 0;

    for (int i = 1; i <= _maxRetries; i++) {
      attempts = i;
      try {
        print('📤 Sending message (attempt $i/$_maxRetries): ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
        
        final resp = await http
            .post(
              Uri.parse('$_baseUrl/chat/message'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'message': message,
                'conversationHistory': history ?? [],
              }),
            )
            .timeout(_timeout);

        print('📥 Response status: ${resp.statusCode}');

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          try {
            final data = jsonDecode(resp.body);
            print('✅ Success: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
            return data is Map<String, dynamic>
                ? data
                : {'response': data.toString()};
          } catch (e) {
            print('⚠️ JSON parse error, returning raw body');
            return {'response': resp.body};
          }
        } else if (resp.statusCode >= 500) {
          lastError = Exception(_serverError);
          if (i < _maxRetries) {
            print('⏳ Server error, retrying in ${_retryDelay.inSeconds}s...');
            await Future.delayed(_retryDelay);
            continue;
          }
        } else if (resp.statusCode == 429) {
          lastError = Exception('Too many requests. Please wait a moment.');
          if (i < _maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } else {
          String msg = _unknownError;
          try {
            final err = jsonDecode(resp.body);
            msg = err['error']?.toString() ?? 
                  err['message']?.toString() ?? 
                  _unknownError;
          } catch (_) {
            msg = 'Error ${resp.statusCode}: ${resp.reasonPhrase ?? _unknownError}';
          }
          throw Exception(msg);
        }
      } on SocketException catch (e) {
        print('❌ Socket error: $e');
        lastError = Exception(_connectionError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on TimeoutException catch (e) {
        print('⏱️ Timeout: $e');
        lastError = Exception(_timeoutError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on http.ClientException catch (e) {
        print('❌ Client error: $e');
        lastError = Exception(_connectionError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on FormatException catch (e) {
        print('❌ Format error: $e');
        lastError = Exception('Invalid response from server');
        throw lastError;
      } catch (e) {
        print('❌ Unknown error: $e');
        lastError = Exception(_sanitize(e.toString()));
        if (i < _maxRetries && _isRetryable(e)) {
          await Future.delayed(_retryDelay);
          continue;
        }
        throw lastError;
      }
    }

    print('❌ All $attempts attempts failed');
    throw lastError ?? Exception(_unknownError);
  }

  /// Test connection - quick check
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to $_baseUrl');
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));
      
      final connected = resp.statusCode == 200 || 
                       resp.statusCode == 404 || 
                       resp.statusCode == 405; // Backend might not have GET /
      
      print(connected ? '✅ Connected' : '❌ Not connected (${resp.statusCode})');
      return connected;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Scan content for security threats
  Future<Map<String, dynamic>> scanContent(String content) async {
    if (content.trim().isEmpty) {
      throw Exception('Content cannot be empty');
    }
    return _postWithRetry('/security/scan-content', {'content': content});
  }

  /// Analyze text
  Future<Map<String, dynamic>> analyzeText(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }
    return _postWithRetry('/text/analyze-text', {'text': text});
  }

  /// Upload and analyze image
  Future<Map<String, dynamic>> uploadImage(String endpoint, File file) async {
    if (!await file.exists()) {
      throw Exception('Image file not found');
    }

    try {
      print('📤 Uploading image: ${file.path}');
      
      final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/$endpoint'));
      req.files.add(await http.MultipartFile.fromPath('image', file.path));

      final stream = await req.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(stream);

      print('📥 Upload response: ${resp.statusCode}');
      return _handleResponse(resp);
    } on SocketException {
      throw Exception(_connectionError);
    } on TimeoutException {
      throw Exception('Image upload timed out. Please try a smaller image.');
    } catch (e) {
      throw Exception(_sanitize(e.toString()));
    }
  }

  /// Generic POST with retry
  Future<Map<String, dynamic>> _postWithRetry(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    Exception? lastError;

    for (int i = 1; i <= _maxRetries; i++) {
      try {
        print('📤 POST $endpoint (attempt $i/$_maxRetries)');
        
        final resp = await http
            .post(
              Uri.parse('$_baseUrl$endpoint'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        return _handleResponse(resp);
      } on SocketException {
        lastError = Exception(_connectionError);
      } on TimeoutException {
        lastError = Exception(_timeoutError);
      } catch (e) {
        lastError = Exception(_sanitize(e.toString()));
        if (!_isRetryable(e)) throw lastError;
      }

      if (i < _maxRetries) {
        print('⏳ Retrying in ${_retryDelay.inSeconds}s...');
        await Future.delayed(_retryDelay);
      }
    }

    throw lastError ?? Exception(_unknownError);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    print('Handling response: ${resp.statusCode}');
    
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> 
            ? data 
            : {'response': data.toString()};
      } catch (_) {
        return {'response': resp.body};
      }
    } else if (resp.statusCode >= 500) {
      throw Exception(_serverError);
    } else if (resp.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment.');
    } else {
      String msg = _unknownError;
      try {
        final err = jsonDecode(resp.body);
        msg = err['error']?.toString() ?? 
              err['message']?.toString() ?? 
              'Error ${resp.statusCode}';
      } catch (_) {
        msg = 'Error ${resp.statusCode}: ${resp.reasonPhrase ?? _unknownError}';
      }
      throw Exception(msg);
    }
  }

  String _sanitize(String err) {
    // Remove URLs
    err = err.replaceAll(RegExp(r'https?://[^\s]+'), '[server]');
    
    // Remove "Exception: " prefix
    err = err.replaceFirst('Exception: ', '');
    
    // Common error patterns
    if (err.contains('SocketException') ||
        err.contains('ClientException') ||
        err.contains('host lookup') ||
        err.contains('Network is unreachable')) {
      return _connectionError;
    }
    
    if (err.contains('Connection refused')) {
      return 'Server is not responding. Please try again later.';
    }
    
    if (err.contains('Connection timed out')) {
      return _timeoutError;
    }
    
    if (err.contains('HandshakeException') ||
        err.contains('Certificate')) {
      return 'Secure connection failed. Please check your network.';
    }
    
    // Return cleaned error or default
    return err.trim().isEmpty ? _unknownError : err.trim();
  }

  bool _isRetryable(dynamic e) {
    final s = e.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('timeout') ||
        s.contains('connection') ||
        s.contains('network') ||
        s.contains('host lookup') ||
        s.contains('refused');
  }

  /// Get connection status info
  Future<Map<String, dynamic>> getConnectionInfo() async {
    final startTime = DateTime.now();
    
    try {
      final connected = await testConnection();
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'connected': connected,
        'latency': latency,
        'status': connected ? 'online' : 'offline',
        'message': connected 
            ? 'Connected (${latency}ms)' 
            : 'Unable to reach server',
      };
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'connected': false,
        'latency': latency,
        'status': 'error',
        'message': _sanitize(e.toString()),
      };
    }
  }
}
