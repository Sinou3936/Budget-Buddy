import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

/// 중앙 HTTP 클라이언트 - 모든 API 호출은 이 클래스를 통해
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _base => AppConfig.apiBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-App-Version': AppConfig.appVersion,
    'X-Platform': AppConfig.platform,
  };

  // ── GET ──────────────────────────────────────
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('$_base$path');
      final res = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 4));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── POST ──────────────────────────────────────
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_base$path');
      final res = await http.post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 4));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── PUT ──────────────────────────────────────
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_base$path');
      final res = await http.put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 4));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── DELETE ──────────────────────────────────────
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final uri = Uri.parse('$_base$path');
      final res = await http.delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 4));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _parse(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'error': 'Invalid response'};
    }
  }
}
