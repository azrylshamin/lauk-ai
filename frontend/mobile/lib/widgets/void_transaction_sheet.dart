import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bill.dart';

class VoidTransactionSheet extends StatelessWidget {
  final Bill bill;
  final bool isVoiding;
  final VoidCallback onConfirmVoid;

  const VoidTransactionSheet({
    super.key,
    required this.bill,
    required this.isVoiding,
    required this.onConfirmVoid,
  });

  @override
  Widget build(BuildContext context) {
    // Generate description for items
    String itemsDescription = '';
    if (bill.items != null && bill.items!.isNotEmpty) {
      if (bill.items!.length == 1) {
        itemsDescription = bill.items!.first.name;
      } else {
        itemsDescription = '${bill.items!.first.name} & others...';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Back arrow (styled like the mockup)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                  onPressed: isVoiding ? null : () => Navigator.pop(context, false),
                ),
                Expanded(
                  child: Text(
                    'Void Transaction',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14142B),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance for centering
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Warning Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE4E4), // Light red background
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: const Color(0xFFED2E7E),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                Text(
                  'Void Transaction?',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14142B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to void this transaction? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF4A4A68),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Order Details Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF4F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8F90A6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '#ORD-${bill.id.toString().padLeft(4, '0')}',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF14142B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'RM ${bill.total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFfb8500),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Dashed Divider
                      SizedBox(
                        height: 1,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boxWidth = constraints.constrainWidth();
                            const dashWidth = 4.0;
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
                      
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Thumbnail
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemsDescription,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF14142B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${bill.itemCount} items in total',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF8F90A6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),

          // Bottom Buttons Container
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isVoiding ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF14142B),
                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isVoiding ? null : onConfirmVoid,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFED2E7E),
                      side: const BorderSide(color: Color(0xFFED2E7E), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isVoiding
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFFED2E7E),
                            ),
                          )
                        : Text(
                            'Confirm Void',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
