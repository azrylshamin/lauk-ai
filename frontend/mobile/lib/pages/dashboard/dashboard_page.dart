import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stats_bar.dart';
import 'scan_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentTab = 0;
  final _statsBarKey = GlobalKey<StatsBarState>();

  void _onTabChanged(int index) {
    setState(() => _currentTab = index);
    _statsBarKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('LaukAI', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  auth.user!.restaurantName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          StatsBar(key: _statsBarKey),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                ScanTab(onBillCreated: () => _statsBarKey.currentState?.refresh()),
                const HistoryTab(),
                const SettingsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: _onTabChanged,
        selectedItemColor: const Color(0xFFfb8500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
