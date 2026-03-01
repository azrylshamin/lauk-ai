import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  final _api = ApiService();
  final _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isOwner => _user?.isOwner ?? false;

  AuthProvider() {
    _api.onUnauthorized = _handleUnauthorized;
    tryAutoLogin();
  }

  void _handleUnauthorized() {
    _user = null;
    _api.setToken(null);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    await _api.loadToken();
    if (_api.hasToken) {
      try {
        _user = await _authService.getMe();
      } catch (_) {
        await _api.setToken(null);
        _user = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _authService.login(email, password);
    await _api.setToken(result['token']);
    _user = result['user'];
    notifyListeners();
  }

  Future<void> register(
      String name, String email, String password, String restaurantName) async {
    final result =
        await _authService.register(name, email, password, restaurantName);
    await _api.setToken(result['token']);
    _user = result['user'];
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.setToken(null);
    _user = null;
    notifyListeners();
  }
}
