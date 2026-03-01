import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import '../models/restaurant.dart';
import '../models/detection_result.dart';
import '../services/customer_service.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final _customerService = CustomerService();
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  File? _image;
  DetectionResult? _result;
  bool _loading = false;
  bool _loadingRestaurants = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _customerService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _loadingRestaurants = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load restaurants';
        _loadingRestaurants = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _estimatePrice() async {
    if (_image == null || _selectedRestaurant == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _customerService.estimatePrice(
        _selectedRestaurant!.id,
        _image!.path,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to estimate price. Please try again.';
        _loading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _error = null;
    });
  }

  void _goBack() {
    setState(() {
      _selectedRestaurant = null;
      _image = null;
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text(
          _selectedRestaurant == null
              ? 'LaukAI'
              : _result != null
                  ? 'Scan Results'
                  : 'Quick Scan',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, 
            color: const Color(0xFF12121D),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _selectedRestaurant != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF12121D)),
                onPressed: _goBack,
              )
            : null,
        actions: [
          if (_selectedRestaurant == null)
            IconButton(
              icon: const Icon(Icons.login_outlined, color: Color(0xFF171725)),
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
        ],
      ),
      body: _selectedRestaurant == null
          ? _buildRestaurantList()
          : _buildScanView(),
    );
  }

  Widget _buildRestaurantList() {
    if (_loadingRestaurants) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    final filteredRestaurants = _restaurants
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search restaurants...',
              hintStyle: TextStyle(color: Colors.blueGrey[300]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFfb8500)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                    color: const Color(0xFFfb8500).withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFfb8500)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Restaurants',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF12121D),
            ),
          ),
        ),
        if (filteredRestaurants.isEmpty)
          const Expanded(
              child: Center(
                  child: Text('No restaurants found',
                      style: TextStyle(color: Colors.grey))))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredRestaurants.length,
              itemBuilder: (context, index) {
                final r = filteredRestaurants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedRestaurant = r),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey[200],
                              child: Image.asset(
                                'assets/images/restaurant_placeholder.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.restaurant,
                                        color: Colors.grey[400]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF12121D)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.address.isNotEmpty ? r.address : "No address"} • ${r.phone}',
                                  style: TextStyle(
                                    color: Colors.blueGrey[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right,
                              color: Color(0xFFfb8500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildScanView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_result == null) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Colors.grey[400]!,
                        strokeWidth: 2,
                        dashPattern: const [8, 6],
                        radius: const Radius.circular(24),
                      ),
                      child: Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF3E0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Color(0xFFfb8500), size: 36),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Tap to upload', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF12121D))),
                                  const SizedBox(height: 6),
                                  Text('food tray', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_incandescent, color: Color(0xFFfb8500)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Take a clear photo of your tray from above for the most accurate estimate.',
                            style: GoogleFonts.inter(color: const Color(0xFF4A4A68), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                              const SizedBox(height: 12),
                              Text('GOOD LIGHTING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6E6E82))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                              const SizedBox(height: 12),
                              Text('CENTER TRAY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6E6E82))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Stack(
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _image != null
                              ? Image.file(_image!, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300]),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfb8500),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text('ANALYSIS COMPLETE', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Detected Items', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF12121D))),
                  Text(
                    'We\'ve identified ${_result!.items.length} item${_result!.items.length != 1 ? 's' : ''} on your tray',
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ..._result!.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[100],
                              child: const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.known ? item.name : '${item.yoloClass} (unpriced)',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: item.known ? FontWeight.w700 : FontWeight.w500,
                                    color: item.known ? const Color(0xFF12121D) : Colors.grey[600],
                                    fontStyle: item.known ? null : FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: item.known ? const Color(0xFF22C55E) : const Color(0xFFfb8500),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item.price != null ? 'RM ${item.price!.toStringAsFixed(2)}' : '-',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF12121D)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info, color: Color(0xFFfb8500), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(color: const Color(0xFF4A4A68), fontSize: 13, height: 1.5),
                              children: const [
                                TextSpan(text: 'Estimate only. ', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: 'Final price is subject to staff verification at the counter.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F9),
            border: Border(top: BorderSide(color: Color(0xFFEAEAEF))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_result != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL PAYABLE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF6E6E82), letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('RM ${_result!.total.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFFfb8500))),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Includes 0% SST', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9EA3AE), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfb8500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 22),
                        const SizedBox(width: 8),
                        Text('Scan Another Tray', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _image != null && !_loading ? _estimatePrice : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfb8500),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFfb8500).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Estimate Price', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.calculate, size: 22),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'POWERED BY LAUKAI VISION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9EA3AE),
                    letterSpacing: 1.2,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
