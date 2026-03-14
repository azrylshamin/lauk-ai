import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transaction_details_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final int orderId;
  final double amount;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header with X
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, 'HOME'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Color(0xFF14142B), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Green check icon
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE4F5E9), // Light green
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00BA88),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Order Completed',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14142B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transaction has been saved to history.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF4A4A68),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Detail Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FINAL AMOUNT',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8F90A6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${amount.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFfb8500),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.payments_outlined, color: Color(0xFFfb8500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFF4F4F6), height: 1),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORDER ID',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8F90A6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#LKA-${orderId.toString().padLeft(6, '0')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF14142B),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.copy, color: Color(0xFF8F90A6), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailsPage(billId: orderId),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          'View Transaction Details  →',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFfb8500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F9),
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, 'SCAN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFfb8500),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 20),
              const SizedBox(width: 8),
              Text(
                'Start New Scan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
