import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for any network / server error surfaced by [ApiClient].
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around `http` with JSON handling and consistent errors.
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = 'https://dummyjson.com'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<dynamic> getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw ApiException('Server responded with ${response.statusCode}.');
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Network error. Check your connection.');
    }
  }

  Future<dynamic> get(String path, [Map<String, dynamic>? params]) {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: params?.map((key, value) => MapEntry(key, '$value')),
    );
    return getJson(uri);
  }
}