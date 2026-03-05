import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

class MenuTab extends StatefulWidget {
  final VoidCallback? onBack;

  const MenuTab({super.key, this.onBack});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final _menuService = MenuService();
  List<MenuItem> _items = [];
  bool _loading = true;

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

  // Fixed YOLO classes from the AI model — must match CLASS_NAMES in ai-service
  static const List<String> _yoloClasses = [
    'Chicken',
    'Egg',
    'Fish',
    'Rice',
    'Sauce',
    'Vegetables',
  ];

  static const Map<String, IconData> _classIcons = {
    'Chicken': Icons.set_meal,
    'Egg': Icons.egg,
    'Fish': Icons.water,
    'Rice': Icons.rice_bowl,
    'Sauce': Icons.soup_kitchen,
    'Vegetables': Icons.eco,
  };

  void _showItemDialog({MenuItem? item}) {
    // For new items, filter out classes already in use
    final usedClasses = _items.map((i) => i.yoloClass).toSet();
    final availableClasses = _yoloClasses
        .where((c) => !usedClasses.contains(c) || c == item?.yoloClass)
        .toList();

    if (item == null && availableClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All AI classes already have menu items')),
      );
      return;
    }

    final yoloController = TextEditingController(
        text: item?.yoloClass ?? availableClasses.first);
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(2) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // We use StatefulBuilder so the dropdown can update locally without rebuilding MenuTab
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item == null ? 'Add New Item' : 'Edit Item',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF12121D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: availableClasses.contains(yoloController.text)
                          ? yoloController.text
                          : availableClasses.first,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category (AI Class)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: availableClasses.map((String cls) {
                        return DropdownMenuItem<String>(
                          value: cls,
                          child: Row(
                            children: [
                              Icon(_classIcons[cls] ?? Icons.restaurant,
                                  size: 20, color: const Color(0xFFfb8500)),
                              const SizedBox(width: 8),
                              Text(cls),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: item != null ? null : (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            yoloController.text = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (RM)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (item != null) ...[
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteItem(item);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(color: Colors.red[600]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final yolo = yoloController.text.trim();
                                final name = nameController.text.trim();
                                final price = double.tryParse(priceController.text.trim());

                                if (name.isEmpty || price == null || (item == null && yolo.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields correctly')),
                                  );
                                  return;
                                }

                                Navigator.pop(ctx);
                                setState(() => _loading = true);

                                try {
                                  if (item == null) {
                                    await _menuService.createMenuItem(yolo, name, price);
                                  } else {
                                    await _menuService.updateMenuItem(item.id, {
                                      'name': name,
                                      'price': price,
                                      if (yolo.isNotEmpty) 'yolo_class': yolo,
                                    });
                                  }
                                  _load();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                    setState(() => _loading = false);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFfb8500),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                item == null ? 'Save Item' : 'Update Item',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Item', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await _menuService.deleteMenuItem(item.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
          setState(() => _loading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F9),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF12121D)),
                      onPressed: widget.onBack,
                    ),
                  Expanded(
                    child: Text(
                      'Menu Management',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF12121D),
                      ),
                    ),
                  ),
                  if (_items.length < _yoloClasses.length)
                    GestureDetector(
                      onTap: () => _showItemDialog(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb8500),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFfb8500).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFfb8500)))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            'No items found.',
                            style: GoogleFonts.inter(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _items[index];

                            return GestureDetector(
                              onTap: () => _showItemDialog(item: item),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Class Icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: item.active
                                            ? const Color(0xFFfb8500).withValues(alpha: 0.08)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _classIcons[item.yoloClass] ?? Icons.restaurant,
                                        color: item.active
                                            ? const Color(0xFFfb8500)
                                            : Colors.grey[400],
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              decoration: item.active ? null : TextDecoration.lineThrough,
                                              color: item.active ? const Color(0xFF12121D) : Colors.grey[400],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.yoloClass,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RM ${item.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: item.active ? const Color(0xFFfb8500) : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Active Toggle
                                    Switch(
                                      value: item.active,
                                      onChanged: (value) {
                                        _menuService.updateMenuItem(item.id, {'active': value}).then((_) => _load());
                                      },
                                      activeColor: const Color(0xFFfb8500),
                                      inactiveThumbColor: Colors.grey[400],
                                      inactiveTrackColor: Colors.grey[200],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

