import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/bill.dart';
import '../../services/bill_service.dart';
import 'transaction_details_page.dart';

class HistoryTab extends StatefulWidget {
  final VoidCallback? onBack;

  const HistoryTab({super.key, this.onBack});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _billService = BillService();
  List<Bill> _bills = [];
  bool _loading = true;
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await _billService.getBills();
      if (mounted) {
        setState(() {
          _bills = bills;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _tabs {
    final now = DateTime.now();
    return [
      'Today, ${DateFormat('d MMM').format(now)}',
      'Yesterday',
      'This Week',
      DateFormat('MMM yyyy').format(now)
    ];
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(billDate).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('d MMM yyyy').format(date).toUpperCase();
  }

  List<Bill> get _filteredBills {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _bills.where((b) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = b.id.toString().contains(q);
        if (!matchId) return false;
      }

      final billDate = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
      final diffDays = today.difference(billDate).inDays;

      switch (_selectedTabIndex) {
        case 0: // Today
          return diffDays == 0;
        case 1: // Yesterday
          return diffDays == 1;
        case 2: // This Week
          return diffDays <= 7;
        case 3: // This Month
          return b.createdAt.year == now.year && b.createdAt.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Bill>> get _groupedFilteredBills {
    final map = <String, List<Bill>>{};
    for (final bill in _filteredBills) {
      final label = _dateLabel(bill.createdAt);
      map.putIfAbsent(label, () => []).add(bill);
    }
    return map;
  }

  Future<void> _showBillDetail(Bill bill) async {
    final voided = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsPage(billId: bill.id),
      ),
    );
    if (voided == true) {
      _loadBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedFilteredBills;
    final labels = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                      onPressed: widget.onBack,
                    )
                  else if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 48),
                  Text(
                    'Transactions',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14142B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, color: Color(0xFF14142B)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search order ID or table...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A3BD), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFA0A3BD)),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      padding: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFFfb8500) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFFfb8500) : const Color(0xFF8F90A6),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F6)),
            
            // List Content
            Expanded(
              child: Container(
                color: const Color(0xFFFAFAFC),
                child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No transactions found',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBills,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: labels.length,
                            itemBuilder: (context, sectionIndex) {
                              final label = labels[sectionIndex];
                              final bills = grouped[label]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sectionIndex > 0) const SizedBox(height: 24),
                                  Text(
                                    label,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6E7191),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...bills.map((bill) {
                                    final title = 'Order #${bill.id.toString().padLeft(4, '0')}';
                                        
                                    return GestureDetector(
                                      onTap: () => _showBillDetail(bill),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF14142B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${DateFormat('hh:mm a').format(bill.createdAt)}  •  ${bill.itemCount} item${bill.itemCount > 1 ? 's' : ''}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: const Color(0xFF8F90A6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              'RM ${bill.total.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF14142B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

