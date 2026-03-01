import 'dart:convert';
import '../models/detection_result.dart';
import 'api_service.dart';

class PredictService {
  final _api = ApiService();

  Future<DetectionResult> detectFood(String imagePath) async {
    final response = await _api.uploadImage('/api/predict', imagePath);
    if (response.statusCode == 200) {
      return DetectionResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to detect food');
  }
}
