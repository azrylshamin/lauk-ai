import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';
import '../settings/employee_manager_page.dart';
import '../settings/restaurant_profile_page.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _restaurantService = RestaurantService();
  Restaurant? _restaurant;
  bool _loadingRest = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    try {
      final r = await _restaurantService.getProfile();
      if (mounted) {
        setState(() {
          _restaurant = r;
          _loadingRest = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRest = false);
    }
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.blueGrey[300],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool showBorder = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: const Color(0xFFFB8500)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        if (showBorder)
          Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14142B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB8500).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('LaukAI Pro',
                          style: TextStyle(
                              color: Color(0xFFFB8500),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Profile Header ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB8500).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFB8500),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- Restaurant Card ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _loadingRest ? 'Loading...' : (_restaurant?.name ?? 'No Restaurant Name'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RestaurantProfilePage(),
                              ),
                            );
                            _loadRestaurant(); // Refresh when back
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFB8500).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                size: 18, color: Color(0xFFFB8500)),
                          ),
                        )
                      ],
                    ),
                    if (_restaurant?.address != null && _restaurant!.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _restaurant!.address!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    if (_restaurant?.phone != null && _restaurant!.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _restaurant!.phone!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _restaurant?.imageUrl != null && _restaurant!.imageUrl!.isNotEmpty
                          ? Image.network(
                              _restaurant!.imageUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, _, s) => Container(
                                height: 120,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Icon(Icons.restaurant,
                                    color: Colors.grey[400], size: 48),
                              ),
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant,
                                  color: Colors.grey[400], size: 48),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Settings Sections ---
              _buildSection(
                title: 'ACCOUNT SETTINGS',
                children: [
                  _buildTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile not implemented yet.')),
                      );
                    },
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change Password not implemented yet.')),
                      );
                    },
                    showBorder: false,
                  ),
                ],
              ),

              _buildSection(
                title: 'RESTAURANT MANAGEMENT',
                children: [
                  _buildTile(
                    icon: Icons.restaurant_menu,
                    title: 'Menu Settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please use the Menu tab or specific item options.')),
                      );
                    },
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.access_time,
                    title: 'Business Hours',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Business Hours not implemented yet.')),
                      );
                    },
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.group_outlined,
                    title: 'Employee Management',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeManagerPage(),
                        ),
                      );
                    },
                    showBorder: false,
                  ),
                ],
              ),

              _buildSection(
                title: 'APP PREFERENCES',
                children: [
                  _buildTile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {},
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode (Coming Soon)',
                    trailing: IgnorePointer(
                      child: Switch(
                        value: false,
                        onChanged: (val) {},
                        activeTrackColor: const Color(0xFFFB8500),
                      ),
                    ),
                    onTap: () {},
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.language,
                    title: 'Language',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('English',
                            style: TextStyle(color: Colors.blueGrey[300])),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {},
                    showBorder: false,
                  ),
                ],
              ),

              _buildSection(
                title: 'SUPPORT',
                children: [
                  _buildTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {},
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.support_agent,
                    title: 'Contact Support',
                    onTap: () {},
                    showBorder: true,
                  ),
                  _buildTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                    showBorder: false,
                  ),
                ],
              ),

              // --- Logout Button ---
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red[100]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[600],
                  ),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              // --- Version String ---
              Center(
                child: Text(
                  'LaukAI v2.4.0 (Build 2024.11)',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
