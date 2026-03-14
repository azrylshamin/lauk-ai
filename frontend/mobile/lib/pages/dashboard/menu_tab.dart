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

  static const Map<String, IconData> _classIcons = {
    'Chicken': Icons.set_meal,
    'Egg': Icons.egg,
    'Fish': Icons.water,
    'Rice': Icons.rice_bowl,
    'Sauce': Icons.soup_kitchen,
    'Vegetables': Icons.eco,
  };

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

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Class Icon / Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: item.active
                                          ? const Color(0xFFfb8500).withValues(alpha: 0.08)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      image: item.imageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(item.imageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: item.imageUrl == null
                                        ? Icon(
                                            _classIcons[item.yoloClass] ?? Icons.restaurant,
                                            color: item.active
                                                ? const Color(0xFFfb8500)
                                                : Colors.grey[400],
                                            size: 32,
                                          )
                                        : null,
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
                                    activeThumbColor: const Color(0xFFfb8500),
                                    inactiveThumbColor: Colors.grey[400],
                                    inactiveTrackColor: Colors.grey[200],
                                  ),
                                ],
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
