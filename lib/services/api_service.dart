import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class ApiService {
  static const String _baseUrl =
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _retryDelay = Duration(seconds: 2);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Test connection to backend
  Future<bool> testConnection() async {
    try {
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));
      
      return resp.statusCode == 200 || 
             resp.statusCode == 404 || 
             resp.statusCode == 405;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Send chat message with retry logic
  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    return await _retryRequest(
      () => _postRequest('/chat/message', {'message': message}),
      'Chat message',
    );
  }

  /// Analyze text content for scams
  Future<Map<String, dynamic>> analyzeText(String text) async {
    return await _retryRequest(
      () => _postRequest('/security/analyze-text', {'text': text}),
      'Text analysis',
    );
  }

  /// Scan content (text + optional image)
  Future<Map<String, dynamic>> scanContent({
    required String content,
    String? imageBase64,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      body['image'] = imageBase64;
    }
    
    return await _retryRequest(
      () => _postRequest('/security/scan-content', body),
      'Content scan',
    );
  }

  /// Check URL safety
  Future<Map<String, dynamic>> checkUrl(String url) async {
    return await _retryRequest(
      () => _postRequest('/security/check-url', {'url': url}),
      'URL check',
    );
  }

  /// Generic POST request
  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // If JSON parsing fails, return raw body
        return {'response': response.body};
      }
    } else if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode}). Please try again.');
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment.');
    } else {
      // Try to parse error message
      try {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Unknown error';
        throw Exception(errorMsg);
      } catch (_) {
        throw Exception('Request failed (${response.statusCode})');
      }
    }
  }

  /// Retry logic with exponential backoff
  Future<Map<String, dynamic>> _retryRequest(
    Future<Map<String, dynamic>> Function() request,
    String operationName,
  ) async {
    Exception? lastError;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('📤 $operationName - Attempt $attempt/$_maxRetries');
        final result = await request();
        print('✅ $operationName - Success');
        return result;
      } on SocketException catch (e) {
        print('❌ $operationName - No internet connection');
        lastError = Exception('No internet connection. Please check and try again.');
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } on TimeoutException catch (e) {
        print('⏱️ $operationName - Timeout');
        lastError = Exception('Request timed out. Please try again.');
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } on Exception catch (e) {
        print('❌ $operationName - Error: $e');
        lastError = e;
        
        // Don't retry on client errors (4xx)
        if (e.toString().contains('(4')) {
          break;
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } catch (e) {
        print('❌ $operationName - Unexpected error: $e');
        lastError = Exception(e.toString());
        break;
      }
    }

    // All retries failed
    print('❌ $operationName - All attempts failed');
    throw lastError ?? Exception('Request failed after $operationName');
  }

  /// Parse safety level from API response
  static String parseSafetyLevel(Map<String, dynamic> data) {
    final safety = (data['safety'] ?? 'Safe').toString().toLowerCase();
    
    if (safety.contains('scam') || safety.contains('phishing')) {
      return 'scam';
    } else if (safety.contains('suspicious') || safety.contains('warning')) {
      return 'warning';
    } else {
      return 'safe';
    }
  }

  /// Get threat level as percentage
  static int getThreatLevel(Map<String, dynamic> data) {
    final level = data['threatLevel'];
    if (level is int) return level.clamp(0, 100);
    if (level is double) return level.toInt().clamp(0, 100);
    return 0;
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse.success(this.data)
      : success = true,
        error = null;

  ApiResponse.error(this.error)
      : success = false,
        data = null;
}
