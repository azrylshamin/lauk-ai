import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/detection_result.dart';
import '../../models/menu_item.dart';
import '../../services/predict_service.dart';
import '../../services/menu_service.dart';
import '../../services/bill_service.dart';
import '../../widgets/add_item_sheet.dart';

class ScanTab extends StatefulWidget {
  final VoidCallback? onBillCreated;
  const ScanTab({super.key, this.onBillCreated});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final _predictService = PredictService();
  final _menuService = MenuService();
  final _billService = BillService();

  File? _image;
  List<DetectionItem> _items = [];
  bool _detecting = false;
  bool _confirming = false;
  String? _error;
  bool _success = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _items = [];
        _error = null;
        _success = false;
      });
    }
  }

  Future<void> _detectFood() async {
    if (_image == null) return;
    setState(() {
      _detecting = true;
      _error = null;
    });
    try {
      final result = await _predictService.detectFood(_image!.path);
      setState(() {
        _items = result.items;
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

  Future<void> _confirmOrder() async {
    if (_items.isEmpty || _hasUnknown) return;
    setState(() => _confirming = true);
    try {
      final billItems = _items
          .map((i) => {
                'menu_item_id': i.menuItemId,
                'name': i.name,
                'price': i.price,
                'quantity': i.quantity,
              })
          .toList();
      await _billService.createBill(billItems, _total);
      setState(() {
        _success = true;
        _confirming = false;
      });
      widget.onBillCreated?.call();
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() {
          _image = null;
          _items = [];
          _success = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create bill';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image upload
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!,
                          fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Tap to select an image',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Detect button
          ElevatedButton(
            onPressed: _image != null && !_detecting ? _detectFood : null,
            child: _detecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Detect Food'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
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
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],

          // Receipt
          if (_items.isNotEmpty && !_success) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Receipt',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () => _showAddItemSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return _buildReceiptRow(item, index);
            }),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_items.length} item(s)',
                    style: TextStyle(color: Colors.grey[600])),
                Text('RM ${_total.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  !_hasUnknown && _items.isNotEmpty && !_confirming
                      ? _confirmOrder
                      : null,
              child: _confirming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_hasUnknown
                      ? 'Assign all items first'
                      : 'Confirm Order'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptRow(DetectionItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isUnknown ? Colors.orange[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isUnknown)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('?',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        Expanded(
                          child: Text(
                            item.known ? item.name : item.yoloClass,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              Row(
                children: [
                  _quantityButton(Icons.remove, () => _updateQuantity(index, -1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _quantityButton(Icons.add, () => _updateQuantity(index, 1)),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                item.price != null
                    ? 'RM ${item.subtotal.toStringAsFixed(2)}'
                    : '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeItem(index),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          // Assign form for unknown items
          if (item.isUnknown) ...[
            const SizedBox(height: 8),
            _AssignForm(
              yoloClass: item.yoloClass,
              onAssign: (name, price) => _assignItem(item, name, price),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddItemSheet(onItemSelected: _addItemFromMenu),
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
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Display name',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _priceController,
            decoration: InputDecoration(
              hintText: 'RM',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    final price =
                        double.tryParse(_priceController.text.trim());
                    if (name.isEmpty || price == null) return;
                    setState(() => _saving = true);
                    await widget.onAssign(name, price);
                    setState(() => _saving = false);
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Assign'),
          ),
        ),
      ],
    );
  }
}
