import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service để gọi đến Firebase Function Proxy cho KiotViet API.
class KiotVietApiService {
  static const String _proxyBaseUrl =
      'https://asia-southeast1-aff-paint-store-app.cloudfunctions.net/kiotVietProxy';

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$_proxyBaseUrl$endpoint',
    ).replace(queryParameters: queryParams);
    return http.get(uri);
  }

  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    return http.post(
      Uri.parse('$_proxyBaseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    return http.put(
      Uri.parse('$_proxyBaseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return http.delete(Uri.parse('$_proxyBaseUrl$endpoint'));
  }
}
