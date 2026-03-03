import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';
import '../../services/employee_service.dart';
import '../../services/auth_service.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Restaurant Profile',
              style:
                  GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _RestaurantProfile(),
          const SizedBox(height: 32),
          Text('Employees',
              style:
                  GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _EmployeeManager(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}



// ─── Restaurant Profile ──────────────────────────────────────────────────────

class _RestaurantProfile extends StatefulWidget {
  const _RestaurantProfile();

  @override
  State<_RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<_RestaurantProfile> {
  final _restaurantService = RestaurantService();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _restaurantService.getProfile();
      _nameController.text = r.name;
      _addressController.text = r.address;
      _phoneController.text = r.phone;
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isOwner) return;

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _restaurantService.updateProfile({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Profile updated!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Failed to update';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Restaurant Name'),
          enabled: isOwner,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Address'),
          enabled: isOwner,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
          enabled: isOwner,
          keyboardType: TextInputType.phone,
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!,
              style: TextStyle(
                  color: _message == 'Profile updated!'
                      ? Colors.green
                      : Colors.red)),
        ],
        if (isOwner) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
        if (!isOwner) ...[
          const SizedBox(height: 8),
          Text('Only the owner can edit the restaurant profile.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ],
    );
  }
}

// ─── Employee Manager ────────────────────────────────────────────────────────

class _EmployeeManager extends StatefulWidget {
  const _EmployeeManager();

  @override
  State<_EmployeeManager> createState() => _EmployeeManagerState();
}

class _EmployeeManagerState extends State<_EmployeeManager> {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _removeEmployee(int id) async {
    try {
      await _employeeService.deleteEmployee(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
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

    if (!isOwner) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Only restaurant owner can manage employees.',
            style: TextStyle(color: Colors.grey[500])),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Invite button / form
        if (!_showInviteForm)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _showInviteForm = true),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Employee'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _inviteNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inviteEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _invitePasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _showInviteForm = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _invite,
                      child: const Text('Invite'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Employee list
        ..._employees.map((emp) {
          if (_deletingId == emp.id) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Remove "${emp.name}"?',
                        style: TextStyle(color: Colors.red[700])),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.red[600]),
                    onPressed: () => _removeEmployee(emp.id),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _deletingId = null),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emp.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: emp.isOwner
                                  ? const Color(0xFFfb8500).withValues(alpha: 0.15)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(emp.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: emp.isOwner
                                      ? const Color(0xFFfb8500)
                                      : Colors.grey[600],
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(emp.email,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (!emp.isOwner)
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red[400]),
                    onPressed: () => setState(() => _deletingId = emp.id),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          );
        }),

        if (_employees.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No employees yet',
                style: TextStyle(color: Colors.grey[500])),
          ),
      ],
    );
  }
}
