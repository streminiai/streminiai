import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _timeout = Duration(seconds: 45);

  // Error messages
  static const String _connectionError =
      'Unable to connect. Please check your internet connection.';
  static const String _serverError =
      'Server temporarily unavailable. Please try again.';
  static const String _timeoutError =
      'Request timed out. Please try again.';
  static const String _unknownError = 'Something went wrong. Please try again.';

  /// Send chat message with retry
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    Exception? lastError;

    for (int i = 1; i <= _maxRetries; i++) {
      try {
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

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          try {
            final data = jsonDecode(resp.body);
            return data is Map<String, dynamic>
                ? data
                : {'response': data.toString()};
          } catch (_) {
            return {'response': resp.body};
          }
        } else if (resp.statusCode >= 500) {
          lastError = Exception(_serverError);
          if (i < _maxRetries) {
            await Future.delayed(_retryDelay);
            continue;
          }
        } else {
          String msg = _unknownError;
          try {
            final err = jsonDecode(resp.body);
            msg = err['error']?.toString() ?? _unknownError;
          } catch (_) {}
          throw Exception(msg);
        }
      } on SocketException {
        lastError = Exception(_connectionError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on TimeoutException {
        lastError = Exception(_timeoutError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } on http.ClientException {
        lastError = Exception(_connectionError);
        if (i < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
      } catch (e) {
        lastError = Exception(_sanitize(e.toString()));
        if (i < _maxRetries && _isRetryable(e)) {
          await Future.delayed(_retryDelay);
          continue;
        }
        throw lastError;
      }
    }

    throw lastError ?? Exception(_unknownError);
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Scan content for security threats
  Future<Map<String, dynamic>> scanContent(String content) async {
    return _postWithRetry('/security/scan-content', {'content': content});
  }

  /// Analyze text
  Future<Map<String, dynamic>> analyzeText(String text) async {
    return _postWithRetry('/text/analyze-text', {'text': text});
  }

  /// Upload and analyze image
  Future<Map<String, dynamic>> uploadImage(String endpoint, File file) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/$endpoint'));
      req.files.add(await http.MultipartFile.fromPath('image', file.path));

      final stream = await req.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(stream);

      return _handleResponse(resp);
    } on SocketException {
      throw Exception(_connectionError);
    } on TimeoutException {
      throw Exception(_timeoutError);
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

      if (i < _maxRetries) await Future.delayed(_retryDelay);
    }

    throw lastError ?? Exception(_unknownError);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        return jsonDecode(resp.body);
      } catch (_) {
        return {'response': resp.body};
      }
    } else if (resp.statusCode >= 500) {
      throw Exception(_serverError);
    } else {
      String msg = _unknownError;
      try {
        final err = jsonDecode(resp.body);
        msg = err['error']?.toString() ?? err['message']?.toString() ?? _unknownError;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  String _sanitize(String err) {
    err = err.replaceAll(RegExp(r'https?://[^\s]+'), '[server]');
    err = err.replaceFirst('Exception: ', '');
    if (err.contains('SocketException') ||
        err.contains('ClientException') ||
        err.contains('host lookup')) {
      return _connectionError;
    }
    return err.trim().isEmpty ? _unknownError : err.trim();
  }

  bool _isRetryable(dynamic e) {
    final s = e.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('timeout') ||
        s.contains('connection') ||
        s.contains('network');
  }
}
