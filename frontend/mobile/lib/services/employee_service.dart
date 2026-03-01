import 'dart:convert';
import 'api_service.dart';

class Employee {
  final int id;
  final String email;
  final String name;
  final String role;

  Employee({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'staff',
    );
  }

  bool get isOwner => role == 'owner';
}

class EmployeeService {
  final _api = ApiService();

  Future<List<Employee>> getEmployees() async {
    final response = await _api.get('/api/employees');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Employee.fromJson(e)).toList();
    }
    throw Exception('Failed to load employees');
  }

  Future<void> deleteEmployee(int id) async {
    final response = await _api.delete('/api/employees/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to remove employee');
    }
  }
}
