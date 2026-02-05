import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient({required String baseUrl}) : baseUrl = _normalizeBaseUrl(baseUrl);

  final String baseUrl;

  static String _normalizeBaseUrl(String s) {
    // Remove trailing slash to keep joining consistent
    return s.endsWith('/') ? s.substring(0, s.length - 1) : s;
  }

  Uri _uri(String path) {
    // Ensure path starts with /
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers({String? token, bool jsonBody = false}) {
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final token = await getToken();
    final uri = _uri(path);

    try {
      return await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('GET failed: $uri\n$e');
    }
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final token = await getToken();
    final uri = _uri(path);

    try {
      return await http
          .post(
            uri,
            headers: _headers(token: token, jsonBody: true),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw Exception('POST failed: $uri\n$e');
    }
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final token = await getToken();
    final uri = _uri(path);

    try {
      return await http
          .put(
            uri,
            headers: _headers(token: token, jsonBody: true),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw Exception('PUT failed: $uri\n$e');
    }
  }

  /// Calls /api/v1/auth/anonymous and stores the token (only if missing)
  Future<void> ensureAnonymousToken() async {
    final existing = await getToken();
    if (existing != null && existing.isNotEmpty) return;

    final uri = _uri('/api/v1/auth/anonymous');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: _headers(jsonBody: true),
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Auth request failed: $uri\n$e');
    }

    if (res.statusCode != 201) {
      throw Exception('Auth failed ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (json['token'] ?? '').toString();
    if (token.isEmpty) {
      throw Exception('Auth returned empty token: ${res.body}');
    }

    await setToken(token);
  }

  /// Optional helper if you want typed JSON parsing in your API classes
  Map<String, dynamic> decodeJsonObject(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Expected JSON object, got: ${decoded.runtimeType}');
    } catch (e) {
      throw Exception('Invalid JSON (${res.statusCode}): ${res.body}\n$e');
    }
  }
}