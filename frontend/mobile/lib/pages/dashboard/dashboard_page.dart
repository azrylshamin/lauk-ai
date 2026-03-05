import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'home_tab.dart';
import 'scan_tab.dart';
import 'history_tab.dart';
import 'menu_tab.dart';
import 'settings_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentTab = 0;

  void _onTabChanged(int index) {
    if (index == 2) {
      // Optional: Handle specifics when scanner is opened
    }
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Hide standard app bar for HomeTab, HistoryTab, ScanTab, and MenuTab as they have their own headers
    final bool showAppBar = _currentTab != 0 && _currentTab != 1 && _currentTab != 2 && _currentTab != 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: showAppBar ? AppBar(
        title: Text('LaukAI', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF12121D))),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  auth.user!.restaurantName,
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFfb8500)),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeTab(onNavigateToHistory: () => _onTabChanged(1)),
          const HistoryTab(),
          ScanTab(onBillCreated: (String action) {
            // After successful scan & bill creation, go to history or home
            if (action == 'HOME') {
              _onTabChanged(0);
            } else if (action == 'SCAN') {
              // Stay on scan tab, it's already reset internally
            } else {
              _onTabChanged(1); // fallback
            }
          }),
          MenuTab(onBack: () => _onTabChanged(0)),
          const SettingsTab(),
        ],
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFfb8500).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFfb8500),
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => _onTabChanged(2),
          child: const Icon(Icons.qr_code_scanner, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'HOME', 0),
            _buildNavItem(Icons.receipt_long, 'HISTORY', 1),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.restaurant_menu, 'MENU', 3),
            _buildNavItem(Icons.settings, 'SETTINGS', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFfb8500) : Colors.blueGrey[300],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFFfb8500) : Colors.blueGrey[300],
            ),
          ),
        ],
      ),
    );
  }
}
