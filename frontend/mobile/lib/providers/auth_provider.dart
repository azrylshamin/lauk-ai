import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/restaurant_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _needsOnboarding = false;
  final _api = ApiService();
  final _authService = AuthService();
  final _restaurantService = RestaurantService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isOwner => _user?.isOwner ?? false;
  bool get needsOnboarding => _needsOnboarding;

  AuthProvider() {
    _api.onUnauthorized = _handleUnauthorized;
    tryAutoLogin();
  }

  void _handleUnauthorized() {
    _user = null;
    _needsOnboarding = false;
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
        // Check if owner needs onboarding
        if (_user!.isOwner) {
          final restaurant = await _restaurantService.getProfile();
          _needsOnboarding = !restaurant.onboardingCompleted;
        }
      } catch (_) {
        await _api.setToken(null);
        _user = null;
        _needsOnboarding = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _authService.login(email, password);
    await _api.setToken(result['token']);
    _user = result['user'];
    // Check onboarding status for owners on login
    if (_user!.isOwner) {
      try {
        final restaurant = await _restaurantService.getProfile();
        _needsOnboarding = !restaurant.onboardingCompleted;
      } catch (_) {
        _needsOnboarding = false;
      }
    }
    notifyListeners();
  }

  Future<void> register(
      String name, String email, String password, String restaurantName) async {
    final result =
        await _authService.register(name, email, password, restaurantName);
    await _api.setToken(result['token']);
    _user = result['user'];
    _needsOnboarding = true;
    notifyListeners();
  }

  void clearOnboardingFlag() {
    _needsOnboarding = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.setToken(null);
    _user = null;
    _needsOnboarding = false;
    notifyListeners();
  }
}
