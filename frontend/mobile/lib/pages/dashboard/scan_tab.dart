import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/detection_result.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../services/predict_service.dart';
import '../../services/menu_service.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/add_item_sheet.dart';
import 'confirm_order_page.dart';

class ScanTab extends StatefulWidget {
  final void Function(String)? onBillCreated;
  const ScanTab({super.key, this.onBillCreated});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final _predictService = PredictService();
  final _menuService = MenuService();
  final _restaurantService = RestaurantService();

  List<File> _images = [];
  int _activeImageIndex = 0;
  List<DetectionItem> _items = [];
  bool _detecting = false;
  String? _error;
  bool _success = false;
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    try {
      final r = await _restaurantService.getProfile();
      if (mounted) setState(() => _restaurant = r);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _images.add(file);
        _activeImageIndex = _images.length - 1;
        _error = null;
        _success = false;
        _detecting = false;
      });
      // Auto detect the newly added image
      _detectFood(file);
    }
  }

  Future<void> _detectFood(File image) async {
    setState(() {
      _detecting = true;
      _error = null;
    });
    try {
      final result = await _predictService.detectFood(image.path);
      setState(() {
        // Merge new detections into existing items
        for (final newItem in result.items) {
          final existingIndex = _items.indexWhere(
            (i) => i.menuItemId != null && i.menuItemId == newItem.menuItemId,
          );
          if (existingIndex >= 0) {
            _items[existingIndex].quantity += newItem.quantity;
          } else {
            _items.add(newItem);
          }
        }
        _detecting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to detect food. Please try again.';
        _detecting = false;
      });
    }
  }

  Future<void> _assignItem(DetectionItem item, String name, double price) async {
    try {
      final menuItem = await _menuService.createMenuItem(
        item.yoloClass,
        name,
        price,
      );
      setState(() {
        item.name = menuItem.name;
        item.price = menuItem.price;
        item.menuItemId = menuItem.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign item: $e')),
        );
      }
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _items[index].quantity += delta;
      if (_items[index].quantity < 1) {
        _items.removeAt(index);
      }
    });
  }

  void _addItemFromMenu(MenuItem menuItem) {
    setState(() {
      final existing = _items.indexWhere((i) => i.menuItemId == menuItem.id);
      if (existing >= 0) {
        _items[existing].quantity++;
      } else {
        _items.add(DetectionItem(
          name: menuItem.name,
          yoloClass: menuItem.yoloClass,
          price: menuItem.price,
          confidence: 1.0,
          known: true,
          menuItemId: menuItem.id,
          quantity: 1,
        ));
      }
    });
  }

  bool get _hasUnknown => _items.any((i) => i.isUnknown);

  double get _total =>
      _items.where((i) => !i.isUnknown).fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _navigateToConfirm(BuildContext context) async {
    if (_items.isEmpty || _hasUnknown) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmOrderPage(
          items: _items,
          total: _total,
          restaurant: _restaurant,
          onOrderCompleted: () {},
        ),
      ),
    );

    // If result is true, the order was successful
    if (result != null && result is String) {
      if (mounted) {
        setState(() {
          _images = [];
          _activeImageIndex = 0;
          _items = [];
          _success = false;
        });
      }
      widget.onBillCreated?.call(result);
    }
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddItemSheet(onItemSelected: _addItemFromMenu),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF14142B)),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text(
                    'LaukAI Scan',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14142B),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance the back button
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                ],
                if (_success) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text('Order confirmed!',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                if (_items.isNotEmpty || _detecting) ...[
                  const SizedBox(height: 24),
                  _buildDetectionList(),
                ],
                // Add some padding at bottom if no items so button isn't squashed if needed
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        if (_items.isNotEmpty && !_success) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF14142B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 48, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text('Tap to take a photo',
                  style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main preview of selected image
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF14142B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_images[_activeImageIndex], fit: BoxFit.cover),
              if (_detecting)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFfb8500)),
                  ),
                ),
              // Image counter badge
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Scan Another button
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: _detecting ? null : _pickImage,
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14142B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Thumbnail gallery row
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

  Widget _buildDetectionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF4F4F6), width: 1.5),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detected Items',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14142B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_items.length} ITEM${_items.length == 1 ? '' : 'S'} FOUND',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFfb8500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F6)),
          if (_detecting)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Scanning image...')),
            )
          else
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Column(
                children: [
                  _buildItemRow(item, index),
                  const Divider(height: 1, color: Color(0xFFF4F4F6)),
                ],
              );
            }),
          // Add Item Button inside the card
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => _showAddItemSheet(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFfb8500),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Item',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFfb8500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(DetectionItem item, int index) {
    if (item.isUnknown) {
      return _buildUnknownItemBlock(item, index);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Name & Confidence
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14142B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${(item.confidence * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00BA88),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CONFIDENCE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00BA88),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quantity Selector
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5EA)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _updateQuantity(index, -1),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.remove, size: 16, color: Color(0xFFfb8500)),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF14142B),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateQuantity(index, 1),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.add, size: 16, color: Color(0xFFfb8500)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Price
          SizedBox(
            width: 70,
            child: Text(
              'RM ${item.price?.toStringAsFixed(2) ?? '-'}',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF14142B),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF8F90A6)),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownItemBlock(DetectionItem item, int index) {
    return Container(
      color: const Color(0xFFFFF9F0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help, size: 16, color: Color(0xFFfb8500)),
              const SizedBox(width: 8),
              Text(
                'Unknown Item detected?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFfb8500),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE4D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MANUAL ASSIGN',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD46900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AssignForm(
            yoloClass: item.yoloClass,
            onAssign: (name, price) => _assignItem(item, name, price),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E7191),
                ),
              ),
              Text(
                'RM ${_total.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF14142B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: !_hasUnknown && _items.isNotEmpty
                ? () => _navigateToConfirm(context)
                : null,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _hasUnknown ? 'Assign all items first' : 'Confirm Order',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_hasUnknown) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFfb8500)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignForm extends StatefulWidget {
  final String yoloClass;
  final Future<void> Function(String name, double price) onAssign;

  const _AssignForm({required this.yoloClass, required this.onAssign});

  @override
  State<_AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<_AssignForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ITEM NAME',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6E7191),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Ayam Goreng',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A3BD), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRICE (RM)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6E7191),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A3BD), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    final price = double.tryParse(_priceController.text.trim());
                    if (name.isEmpty || price == null) return;
                    setState(() => _saving = true);
                    await widget.onAssign(name, price);
                    setState(() => _saving = false);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFfb8500),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Assign',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
