import 'dart:convert';
import '../models/restaurant.dart';
import '../models/detection_result.dart';
import 'api_service.dart';

class CustomerService {
  final _api = ApiService();

  Future<List<Restaurant>> getRestaurants() async {
    final response = await _api.get('/api/customer/restaurants');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((r) => Restaurant.fromJson(r)).toList();
    }
    throw Exception('Failed to load restaurants');
  }

  Future<DetectionResult> estimatePrice(
      int restaurantId, String imagePath) async {
    final response = await _api.uploadImage(
      '/api/customer/restaurants/$restaurantId/estimate',
      imagePath,
    );
    if (response.statusCode == 200) {
      return DetectionResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to estimate price');
  }
}
