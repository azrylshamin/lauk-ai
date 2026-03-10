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
  List<File> _images = [];
  int _activeImageIndex = 0;
  List<DetectionItem> _accumulatedItems = [];
  double _accumulatedSst = 0.0;
  double _accumulatedSc = 0.0;
  bool _hasResults = false;
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
      final file = File(picked.path);
      setState(() {
        _images.add(file);
        _activeImageIndex = _images.length - 1;
        _error = null;
      });
      // If we already have results, auto-estimate the new image
      if (_hasResults) {
        _estimateSingleImage(file);
      }
    }
  }

  Future<void> _estimatePrice() async {
    if (_images.isEmpty || _selectedRestaurant == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _accumulatedSst = 0.0;
      _accumulatedSc = 0.0;
      for (final image in _images) {
        final result = await _customerService.estimatePrice(
          _selectedRestaurant!.id,
          image.path,
        );
        _mergeItems(result.items);
        _accumulatedSst += result.sstAmount;
        _accumulatedSc += result.scAmount;
      }
      setState(() {
        _hasResults = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to estimate price. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _estimateSingleImage(File image) async {
    if (_selectedRestaurant == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _customerService.estimatePrice(
        _selectedRestaurant!.id,
        image.path,
      );
      setState(() {
        _mergeItems(result.items);
        _accumulatedSst += result.sstAmount;
        _accumulatedSc += result.scAmount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to estimate price. Please try again.';
        _loading = false;
      });
    }
  }

  void _mergeItems(List<DetectionItem> newItems) {
    for (final newItem in newItems) {
      final existingIndex = _accumulatedItems.indexWhere(
        (i) => i.menuItemId != null && i.menuItemId == newItem.menuItemId,
      );
      if (existingIndex >= 0) {
        _accumulatedItems[existingIndex].quantity += newItem.quantity;
      } else {
        _accumulatedItems.add(newItem);
      }
    }
  }

  double get _estimatedTotal =>
      _accumulatedItems.fold(0.0, (sum, i) => sum + i.subtotal);

  double get _grandTotal => _estimatedTotal + _accumulatedSst + _accumulatedSc;

  bool get _hasTax => _accumulatedSst > 0 || _accumulatedSc > 0;

  void _reset() {
    setState(() {
      _images = [];
      _activeImageIndex = 0;
      _accumulatedItems = [];
      _accumulatedSst = 0.0;
      _accumulatedSc = 0.0;
      _hasResults = false;
      _error = null;
    });
  }

  void _goBack() {
    setState(() {
      _selectedRestaurant = null;
      _images = [];
      _activeImageIndex = 0;
      _accumulatedItems = [];
      _hasResults = false;
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
              : _hasResults
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
                              child: r.imageUrl != null
                                  ? Image.network(
                                      r.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: 64,
                                      height: 64,
                                      errorBuilder: (context, _, s) =>
                                          Icon(Icons.restaurant,
                                              color: Colors.grey[400]),
                                    )
                                  : Icon(Icons.restaurant,
                                      color: Colors.grey[400]),
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
                if (!_hasResults) ...[
                  _buildPreScanImageSection(),
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
                  _buildResultsImageSection(),
                  const SizedBox(height: 32),
                  Text('Detected Items', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF12121D))),
                  Text(
                    'We\'ve identified ${_accumulatedItems.length} item${_accumulatedItems.length != 1 ? 's' : ''} on your tray',
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ..._accumulatedItems.map((item) {
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
                                      item.quantity > 1
                                          ? '${(item.confidence * 100).toStringAsFixed(0)}% confidence  x${item.quantity}'
                                          : '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item.price != null ? 'RM ${item.subtotal.toStringAsFixed(2)}' : '-',
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
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPreScanImageSection() {
    if (_images.isEmpty) {
      return GestureDetector(
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
            child: Column(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main preview
        Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_images[_activeImageIndex], fit: BoxFit.cover),
              if (_loading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFfb8500)),
                  ),
                ),
              // Image counter badge
              if (_images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_activeImageIndex + 1} / ${_images.length}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              // Add another image button
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo, size: 16, color: Color(0xFF14142B)),
                        const SizedBox(width: 6),
                        Text(
                          'Add Another Photo',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF14142B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Thumbnail gallery
        if (_images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isActive = index == _activeImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeImageIndex = index),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? const Color(0xFFfb8500) : const Color(0xFFE5E5EA),
                        width: isActive ? 2.5 : 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(_images[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              height: 240,
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
                child: Image.file(_images[_activeImageIndex], fit: BoxFit.cover),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFfb8500)),
                  ),
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
            // Image counter badge
            if (_images.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activeImageIndex + 1} / ${_images.length}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            // Scan another image button
            Positioned(
              bottom: 12,
              left: 12,
              child: GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_a_photo, size: 16, color: Color(0xFF14142B)),
                      const SizedBox(width: 6),
                      Text(
                        'Scan Another',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF14142B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Thumbnail gallery
        if (_images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isActive = index == _activeImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeImageIndex = index),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? const Color(0xFFfb8500) : const Color(0xFFE5E5EA),
                        width: isActive ? 2.5 : 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(_images[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F9),
        border: Border(top: BorderSide(color: Color(0xFFEAEAEF))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasResults) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL PAYABLE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF6E6E82), letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('RM ${_grandTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFFfb8500))),
                  ],
                ),
                if (_hasTax)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_accumulatedSst > 0)
                          Text('SST: RM ${_accumulatedSst.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9EA3AE), fontWeight: FontWeight.w500)),
                        if (_accumulatedSc > 0)
                          Text('SC: RM ${_accumulatedSc.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9EA3AE), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('No tax applied', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9EA3AE), fontWeight: FontWeight.w500)),
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
                    Text('Start New Scan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _images.isNotEmpty && !_loading ? _estimatePrice : null,
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
    );
  }
}
