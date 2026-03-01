import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bill.dart';
import '../services/bill_service.dart';

class StatsBar extends StatefulWidget {
  const StatsBar({super.key});

  @override
  State<StatsBar> createState() => StatsBarState();
}

class StatsBarState extends State<StatsBar> {
  final _billService = BillService();
  BillStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
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
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildStatCard("Today's Bills",
              _loading ? '-' : '${_stats?.billCount ?? 0}', Icons.receipt),
          _buildStatCard(
              'Revenue',
              _loading
                  ? '-'
                  : 'RM ${_stats?.revenue.toStringAsFixed(2) ?? '0.00'}',
              Icons.trending_up),
          _buildStatCard(
              'Average',
              _loading
                  ? '-'
                  : 'RM ${_stats?.average.toStringAsFixed(2) ?? '0.00'}',
              Icons.analytics),
          _buildStatCard(
              'Accuracy',
              _loading
                  ? '-'
                  : _stats?.accuracy != null
                      ? '${_stats!.accuracy!.toStringAsFixed(1)}%'
                      : 'N/A',
              Icons.precision_manufacturing),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
