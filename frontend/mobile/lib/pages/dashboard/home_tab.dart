import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/bill_service.dart';
import '../../models/bill.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToHistory;

  const HomeTab({super.key, required this.onNavigateToHistory});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _billService = BillService();
  bool _loading = true;
  BillStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _billService.getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'User';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFfb8500),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: const AssetImage('assets/images/user_avatar.png'), // Add or use placeholder
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey[600]),
                        ),
                        Text(
                          '$userName!',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF12121D)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded, color: Color(0xFF12121D)),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFfb8500),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S REVENUE",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFfb8500),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Text(
                          'RM ${_stats?.revenue.toStringAsFixed(2) ?? '0.00'}',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF12121D),
                          ),
                        ),
                  const SizedBox(height: 12),
                  if (_stats?.revenueGrowth != null)
                    Row(
                      children: [
                        Icon(
                          _stats!.revenueGrowth! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: _stats!.revenueGrowth! >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_stats!.revenueGrowth! >= 0 ? '+' : ''}${_stats!.revenueGrowth!.toStringAsFixed(0)}% from yesterday',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _stats!.revenueGrowth! >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.receipt_long,
                    iconColor: const Color(0xFFfb8500),
                    iconBgColor: const Color(0xFFFFF3E0),
                    title: 'Total Bills',
                    value: _loading ? '-' : '${_stats?.billCount ?? 0}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.restaurant_menu,
                    iconColor: const Color(0xFFfb8500),
                    iconBgColor: const Color(0xFFFFF3E0),
                    title: 'Top Item',
                    value: _loading ? '-' : (_stats?.topItem ?? '-'),
                    isTextValue: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF12121D),
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFfb8500),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Transactions List
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ))
            else if (_stats == null || _stats!.recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ..._stats!.recentTransactions.map((bill) => _buildTransactionCard(bill)),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.blueGrey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: isTextValue
                ? GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF12121D))
                : GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF12121D)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Bill bill) {
    final identifier = 'Order #${bill.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              color: Colors.blueGrey[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  identifier,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF12121D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('hh:mm a').format(bill.createdAt)} • ${bill.itemCount} Items',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${bill.total.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF12121D),
            ),
          ),
        ],
      ),
    );
  }
}
