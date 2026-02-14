import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiClient {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();

    debugPrint('token: $token');

    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body}) async {
    return http.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    return http.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
  }
}
