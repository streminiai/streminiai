
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "https://api.stremini.com/v1";

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      // Handle network or other errors
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      // Handle network or other errors
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<dynamic> uploadImage(String endpoint, File image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/$endpoint'));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedData = jsonDecode(responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedData;
      } else {
        throw Exception(
          'Request failed with status: ${response.statusCode}. Message: ${decodedData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception(
        'Request failed with status: ${response.statusCode}. Message: ${responseBody['message'] ?? 'Unknown error'}',
      );
    }
  }
}

// Example of a data model (can be in a separate file)
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'],
      message: json['message'],
    );
  }
}
