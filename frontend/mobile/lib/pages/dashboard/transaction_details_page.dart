import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/bill.dart';
import '../../services/bill_service.dart';
import '../../widgets/void_transaction_sheet.dart';

class TransactionDetailsPage extends StatefulWidget {
  final int billId;

  const TransactionDetailsPage({super.key, required this.billId});

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  final _billService = BillService();
  Bill? _bill;
  bool _loading = true;
  bool _voiding = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _voidTransaction() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return VoidTransactionSheet(
            bill: _bill!,
            isVoiding: _voiding,
            onConfirmVoid: () async {
              setModalState(() => _voiding = true);
              try {
                await _billService.deleteBill(widget.billId);
                if (ctx.mounted) {
                  Navigator.pop(ctx, true); // Close modal returning true
                }
              } catch (e) {
                if (ctx.mounted) {
                  setModalState(() => _voiding = false);
                  Navigator.pop(ctx, false); // Close modal returning false
                }
              }
            },
          );
        }
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, true); // Pop the detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction voided successfully', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFfb8500),
        ),
      );
    } else if (confirmed == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to void transaction', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFED2E7E),
        ),
      );
    }
  }

  Future<void> _loadDetail() async {
    try {
      final bill = await _billService.getBillDetail(widget.billId);
      if (mounted) {
        setState(() {
          _bill = bill;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Transaction Details',
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFfb8500)))
                  : _bill == null
                      ? Center(
                          child: Text(
                            'Failed to load bill',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFBE4D2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFfb8500),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Amount & Info
                              Text(
                                'RM ${_bill!.total.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF14142B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order ID #TR-${_bill!.id.toString().padLeft(4, '0')}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF6E7191),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMMM d, h:mm a').format(_bill!.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF6E7191),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Receipt Card
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
                                      children: [
                                        const Icon(Icons.receipt_long, color: Color(0xFFfb8500), size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Itemized Receipt',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF14142B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Items
                                    if (_bill!.items != null)
                                      ..._bill!.items!.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                        color: const Color(0xFF14142B),
                                                      ),
                                                    ),
                                                    // Note: We don't have "Extra Sambal" notes in the DB right now, 
                                                    // but we could add a placeholder or leave it out.
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'x${item.quantity}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF8F90A6),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  'RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF14142B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      
                                    const SizedBox(height: 8),
                                    
                                    // Dashed divider
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
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Subtotal & Tax Breakdown
                                    if (_bill!.hasTaxBreakdown) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Subtotal', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                          Text('RM ${_bill!.subtotal!.toStringAsFixed(2)}', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                        ],
                                      ),
                                      if (_bill!.sstAmount > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('SST', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                            Text('RM ${_bill!.sstAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                      if (_bill!.scAmount > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Service Charge', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                            Text('RM ${_bill!.scAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ] else ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Subtotal', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                          Text('RM ${_bill!.total.toStringAsFixed(2)}', style: GoogleFonts.inter(color: const Color(0xFF6E7191), fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 16),

                                    // Grand Total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Grand Total',
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF14142B),
                                          ),
                                        ),
                                        Text(
                                          'RM ${_bill!.total.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFfb8500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 48),
                              TextButton(
                                onPressed: _voidTransaction,
                                child: Text(
                                  'Void Transaction',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFED2E7E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
