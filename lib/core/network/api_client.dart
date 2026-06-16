import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _httpClient.get(
      _uri(path, queryParameters),
      headers: await _headers(authenticated: authenticated),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: await _headers(authenticated: authenticated, hasBody: true),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _httpClient.delete(
      _uri(path),
      headers: await _headers(authenticated: authenticated),
    );

    return _decodeResponse(response);
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final cleanQuery = queryParameters?.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    return uri.replace(queryParameters: cleanQuery);
  }

  Future<Map<String, String>> _headers({
    required bool authenticated,
    bool hasBody = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (hasBody) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = _decodeJsonObject(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: decoded['message']?.toString() ?? 'Request failed.',
      errors: _parseErrors(decoded['errors']),
    );
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            'The API returned a non-JSON response. Check the Laravel server and ngrok tunnel.',
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'The API returned an unexpected response.',
    );
  }

  Map<String, List<String>> _parseErrors(Object? rawErrors) {
    if (rawErrors is! Map<String, dynamic>) {
      return const {};
    }

    return rawErrors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((item) => item.toString()).toList());
      }

      return MapEntry(key, [value.toString()]);
    });
  }
}
