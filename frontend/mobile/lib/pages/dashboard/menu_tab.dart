import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final _menuService = MenuService();
  List<MenuItem> _items = [];
  bool _loading = true;
  bool _showAddForm = false;
  int? _editingId;
  int? _deletingId;

  final _addYoloController = TextEditingController();
  final _addNameController = TextEditingController();
  final _addPriceController = TextEditingController();

  final _editNameController = TextEditingController();
  final _editPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _menuService.getMenuItems();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem() async {
    final yolo = _addYoloController.text.trim();
    final name = _addNameController.text.trim();
    final price = double.tryParse(_addPriceController.text.trim());
    if (yolo.isEmpty || name.isEmpty || price == null) return;

    try {
      await _menuService.createMenuItem(yolo, name, price);
      _addYoloController.clear();
      _addNameController.clear();
      _addPriceController.clear();
      setState(() => _showAddForm = false);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _updateItem(int id) async {
    final name = _editNameController.text.trim();
    final price = double.tryParse(_editPriceController.text.trim());
    if (name.isEmpty || price == null) return;

    try {
      await _menuService.updateMenuItem(id, {'name': name, 'price': price});
      setState(() => _editingId = null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await _menuService.deleteMenuItem(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() => _deletingId = null);
  }

  Future<void> _toggleActive(MenuItem item) async {
    try {
      await _menuService.updateMenuItem(item.id, {'active': !item.active});
      _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _addYoloController.dispose();
    _addNameController.dispose();
    _addPriceController.dispose();
    _editNameController.dispose();
    _editPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menu Manager', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF12121D))),
              if (!_showAddForm)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfb8500),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_showAddForm)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Menu Item', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addYoloController,
                    decoration: InputDecoration(
                      labelText: 'YOLO Class',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addPriceController,
                    decoration: InputDecoration(
                      labelText: 'Price (RM)',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showAddForm = false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFfb8500), foregroundColor: Colors.white),
                        child: const Text('Save Item'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Item list
          ..._items.map((item) {
            if (_editingId == item.id) return _buildEditRow(item);
            if (_deletingId == item.id) return _buildDeleteConfirmRow(item);
            return _buildItemRow(item);
          }),

          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No menu items yet', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.active,
            onChanged: (_) => _toggleActive(item),
            activeColor: const Color(0xFFfb8500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: Colors.grey[400]!),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    decoration: item.active ? null : TextDecoration.lineThrough,
                    color: item.active ? const Color(0xFF12121D) : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.yoloClass,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey[400]),
                ),
              ],
            ),
          ),
          Text(
            'RM ${item.price.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFFfb8500)),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[600]),
            onPressed: () {
              _editNameController.text = item.name;
              _editPriceController.text = item.price.toStringAsFixed(2);
              setState(() => _editingId = item.id);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
            onPressed: () => setState(() => _deletingId = item.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditRow(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _editNameController,
              decoration: InputDecoration(
                labelText: 'Name',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _editPriceController,
              decoration: InputDecoration(
                labelText: 'Price',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
            onPressed: () => _updateItem(item.id),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.grey, size: 24),
            onPressed: () => setState(() => _editingId = null),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConfirmRow(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Delete "${item.name}"?', style: GoogleFonts.inter(color: Colors.red[700], fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => setState(() => _deletingId = null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _deleteItem(item.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
