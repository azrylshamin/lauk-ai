import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/detection_result.dart';
import '../../services/bill_service.dart';
import 'order_success_page.dart';

class ConfirmOrderPage extends StatefulWidget {
  final List<DetectionItem> items;
  final double total;
  final VoidCallback onOrderCompleted;

  const ConfirmOrderPage({
    super.key,
    required this.items,
    required this.total,
    required this.onOrderCompleted,
  });

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  final _billService = BillService();
  bool _confirming = false;
  bool _success = false;
  String? _error;

  Future<void> _completeOrder() async {
    setState(() => _confirming = true);
    try {
      final billItems = widget.items
          .map((i) => {
                'menu_item_id': i.menuItemId,
                'name': i.name,
                'price': i.price,
                'quantity': i.quantity,
              })
          .toList();
      
      final createdBill = await _billService.createBill(billItems, widget.total);
      
      setState(() {
        _success = true;
        _confirming = false;
      });
      
      widget.onOrderCompleted();
      
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessPage(
              orderId: createdBill.id,
              amount: createdBill.total,
            ),
          ),
        );
        if (mounted) {
           Navigator.pop(context, result ?? 'SCAN');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create order: $e';
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                      onPressed: () {
                        if (!_confirming && !_success) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Confirm Order',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF14142B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Order Summary',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14142B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Order Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Items List
                          ...List.generate(widget.items.length, (index) {
                            final item = widget.items[index];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Image placeholder
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F4F6),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.fastfood, color: Colors.grey),
                                        // In a real app we'd load the item image here if available:
                                        // child: ClipRRect(
                                        //   borderRadius: BorderRadius.circular(12),
                                        //   child: Image.network(item.imageUrl, fit: BoxFit.cover),
                                        // ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF14142B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Qty: ${item.quantity}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF8F90A6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'RM ${item.subtotal.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF14142B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < widget.items.length - 1)
                                  const Divider(height: 1, color: Color(0xFFF4F4F6)),
                              ],
                            );
                          }),
                          
                          // Dashed Divider
                          SizedBox(
                            height: 20,
                            child: Stack(
                              children: [
                                Center(
                                  child: Container(
                                    height: 1,
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (BuildContext context, BoxConstraints constraints) {
                                        final boxWidth = constraints.constrainWidth();
                                        const dashWidth = 5.0;
                                        const dashHeight = 1.0;
                                        final dashCount = (boxWidth / (2 * dashWidth)).floor();
                                        return Flex(
                                          direction: Axis.horizontal,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: List.generate(dashCount, (_) {
                                            return SizedBox(
                                              width: dashWidth,
                                              height: dashHeight,
                                              child: const DecoratedBox(
                                                decoration: BoxDecoration(color: Color(0xFFE5E5EA)),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Grand Total
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF9F0),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Grand Total',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF14142B),
                                  ),
                                ),
                                Text(
                                  'RM ${widget.total.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFfb8500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE4D2).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFBE4D2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info, color: Color(0xFFfb8500), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Scanning completed. Please verify the items and the total amount before finalizing the order.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF4A4A68),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                    
                    const SizedBox(height: 100), // Padding for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _confirming ? null : _completeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFfb8500),
          disabledBackgroundColor: const Color(0xFFfb8500).withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: _confirming
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Complete Order',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Color(0xFFfb8500)),
                  ),
                ],
              ),
      ),
    );
  }
}
