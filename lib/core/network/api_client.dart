import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _defaultHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (AppConfig.backendApiKey.isNotEmpty) {
      headers['X-Api-Key'] = AppConfig.backendApiKey;
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${AppConfig.backendBaseUrl}$path')
        .replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _performRequest(
      () => _client.get(uri, headers: {..._defaultHeaders(), ...?headers}),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _performRequest(
      () => _client.post(
        uri,
        headers: {..._defaultHeaders(), ...?headers},
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _performRequest(
      () => _client.put(
        uri,
        headers: {..._defaultHeaders(), ...?headers},
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _performRequest(
      () => _client.delete(uri, headers: {..._defaultHeaders(), ...?headers}),
    );
  }

  Future<Map<String, dynamic>> _performRequest(
    Future<http.Response> Function() requestFn, {
    int retries = 2,
  }) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await requestFn().timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw ApiException(
                statusCode: 408,
                message: 'Request timed out',
              ),
            );
        return _processResponse(response);
      } on TimeoutException catch (e) {
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } on SocketException catch (e) {
        if (attempt >= retries) {
          throw ApiException(statusCode: 503, message: 'Network unavailable: ${e.message}');
        }
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      } on ApiException catch (e) {
        if (_isTransientStatus(e.statusCode) && attempt < retries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw ApiException(statusCode: 500, message: 'Failed to complete request');
  }

  bool _isTransientStatus(int statusCode) {
    return [408, 429, 500, 502, 503, 504].contains(statusCode);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = _decodeJson(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['message']?.toString() ??
            'Backend request failed with status ${response.statusCode}',
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
