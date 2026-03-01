import 'dart:convert';
import '../models/bill.dart';
import 'api_service.dart';

class BillService {
  final _api = ApiService();

  Future<BillStats> getStats() async {
    final response = await _api.get('/api/bills/stats');
    if (response.statusCode == 200) {
      return BillStats.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load stats');
  }

  Future<List<Bill>> getBills() async {
    final response = await _api.get('/api/bills');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((b) => Bill.fromJson(b)).toList();
    }
    throw Exception('Failed to load bills');
  }

  Future<Bill> getBillDetail(int id) async {
    final response = await _api.get('/api/bills/$id');
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load bill');
  }

  Future<void> createBill(
      List<Map<String, dynamic>> items, double total) async {
    final response = await _api.post('/api/bills', {
      'items': items,
      'total': total,
    });
    if (response.statusCode != 201) {
      throw Exception('Failed to create bill');
    }
  }
}
