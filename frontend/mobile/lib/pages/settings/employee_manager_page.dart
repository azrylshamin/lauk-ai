import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/employee_service.dart';
import '../../services/auth_service.dart';

class EmployeeManagerPage extends StatefulWidget {
  const EmployeeManagerPage({super.key});

  @override
  State<EmployeeManagerPage> createState() => _EmployeeManagerPageState();
}

class _EmployeeManagerPageState extends State<EmployeeManagerPage> {
  final _employeeService = EmployeeService();
  final _authService = AuthService();
  List<Employee> _employees = [];
  bool _loading = true;
  bool _showInviteForm = false;
  int? _deletingId;

  final _inviteNameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _invitePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final employees = await _employeeService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final name = _inviteNameController.text.trim();
    final email = _inviteEmailController.text.trim();
    final password = _invitePasswordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    try {
      await _authService.invite(name, email, password);
      _inviteNameController.clear();
      _inviteEmailController.clear();
      _invitePasswordController.clear();
      setState(() => _showInviteForm = false);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _removeEmployee(int id) async {
    try {
      await _employeeService.deleteEmployee(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() => _deletingId = null);
  }

  @override
  void dispose() {
    _inviteNameController.dispose();
    _inviteEmailController.dispose();
    _invitePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        surfaceTintColor: Colors.transparent,
      ),
      body: !isOwner
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only the restaurant owner can manage employees.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (!_showInviteForm)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFFB8500).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFFFB8500),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => setState(() => _showInviteForm = true),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invite New Employee', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Invite Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _inviteNameController,
                              decoration: const InputDecoration(labelText: 'Full Name'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _inviteEmailController,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _invitePasswordController,
                              decoration: const InputDecoration(labelText: 'Temporary Password'),
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(() => _showInviteForm = false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFB8500),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _invite,
                                    child: const Text('Send Invite'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    Text('Current Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                    const SizedBox(height: 12),

                    ..._employees.map((emp) {
                      if (_deletingId == emp.id) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Remove "${emp.name}"?', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500)),
                              ),
                              IconButton(
                                icon: Icon(Icons.check_circle, color: Colors.red[600]),
                                onPressed: () => _removeEmployee(emp.id),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.grey[600]),
                                onPressed: () => setState(() => _deletingId = null),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFFB8500).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFFFB8500),
                              child: Text(emp.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: emp.isOwner ? const Color(0xFFFB8500).withValues(alpha: 0.15) : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          emp.role,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: emp.isOwner ? const Color(0xFFFB8500) : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(emp.email, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            if (!emp.isOwner)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                onPressed: () => setState(() => _deletingId = emp.id),
                              ),
                          ],
                        ),
                      );
                    }),
                    
                    if (_employees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('No employees found.', style: TextStyle(color: Colors.grey[500])),
                        ),
                      ),
                  ],
                ),
    );
  }
}
