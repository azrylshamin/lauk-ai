import 'dart:convert';
import '../models/restaurant.dart';
import 'api_service.dart';

class RestaurantService {
  final _api = ApiService();

  Future<Restaurant> getProfile() async {
    final response = await _api.get('/api/restaurant');
    if (response.statusCode == 200) {
      return Restaurant.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load restaurant profile');
  }

  Future<Restaurant> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.patch('/api/restaurant', data);
    if (response.statusCode == 200) {
      return Restaurant.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update restaurant profile');
  }
}
