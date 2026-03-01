import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;
  VoidCallback? onUnauthorized;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('laukai_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('laukai_token', token);
    } else {
      await prefs.remove('laukai_token');
    }
  }

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<http.Response> get(String path) async {
    final response = await http.get(
      Uri.parse('$apiUrl$path'),
      headers: _authHeaders,
    );
    _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$apiUrl$path'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$apiUrl$path'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$apiUrl$path'),
      headers: _authHeaders,
    );
    _handleUnauthorized(response);
    return response;
  }

  Future<http.Response> uploadImage(String path, String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl$path'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    final ext = filePath.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      filePath,
      contentType: MediaType('image', ext),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _handleUnauthorized(response);
    return response;
  }

  void _handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
  }
}

typedef VoidCallback = void Function();
