import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  final String message;
  final int statusCode;

  ServerException(this.message, this.statusCode);

  @override
  String toString() => 'ServerException: $statusCode - $message';
}

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({
    this.baseUrl = 'http://127.0.0.1:8000/api/v1/',
    this.defaultHeaders = const {},
  });

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic mockResponse,
  }) async {
    if (mockResponse != null) {
      return mockResponse;
    }

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    try {
      final response = await http.get(
        uri,
        headers: {...defaultHeaders, ...?headers},
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No Internet connection');
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    dynamic mockResponse,
  }) async {
    if (mockResponse != null) {
      return mockResponse;
    }

    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...defaultHeaders,
          ...?headers,
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No Internet connection');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final responseJson = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseJson;
    } else {
      throw ServerException(
        responseJson['message']?.toString() ?? 'Unknown server error',
        response.statusCode,
      );
    }
  }
}
