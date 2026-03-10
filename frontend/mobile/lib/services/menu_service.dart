import 'dart:convert';
import '../models/menu_item.dart';
import 'api_service.dart';

class MenuService {
  final _api = ApiService();

  Future<List<MenuItem>> getMenuItems() async {
    final response = await _api.get('/api/menu-items');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((m) => MenuItem.fromJson(m)).toList();
    }
    throw Exception('Failed to load menu items');
  }

  Future<MenuItem> createMenuItem(
      String yoloClass, String name, double price) async {
    final response = await _api.post('/api/menu-items', {
      'yolo_class': yoloClass,
      'name': name,
      'price': price,
    });
    if (response.statusCode == 201) {
      return MenuItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create menu item');
  }

  Future<MenuItem> updateMenuItem(int id, Map<String, dynamic> data) async {
    final response = await _api.patch('/api/menu-items/$id', data);
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update menu item');
  }

  Future<void> deleteMenuItem(int id) async {
    final response = await _api.delete('/api/menu-items/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu item');
    }
  }

  Future<MenuItem> uploadMenuItemImage(int id, String filePath) async {
    final response =
        await _api.uploadEntityImage('/api/menu-items/$id/image', filePath);
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to upload menu item image');
  }

  Future<MenuItem> deleteMenuItemImage(int id) async {
    final response = await _api.delete('/api/menu-items/$id/image');
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to delete menu item image');
  }
}
