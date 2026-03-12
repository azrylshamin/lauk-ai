import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String restaurantName) async {
    final response = await _api.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'restaurantName': restaurantName,
    });
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<User> getMe() async {
    final response = await _api.get('/api/auth/me');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<void> invite(String name, String email, String password) async {
    final response = await _api.post('/api/auth/invite', {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractError(response.body));
    }
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final response = await _api.patch('/api/auth/profile', {
      'name': name,
      'email': email,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _api.post('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.statusCode == 200) return;
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<User> uploadProfileImage(String filePath) async {
    final response =
        await _api.uploadEntityImage('/api/auth/profile/image', filePath);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  Future<User> deleteProfileImage() async {
    final response = await _api.delete('/api/auth/profile/image');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _extractError(response.body));
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error'] ?? data['message'] ?? 'Something went wrong';
    } catch (_) {
      return 'Something went wrong';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
