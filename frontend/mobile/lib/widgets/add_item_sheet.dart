import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class AddItemSheet extends StatefulWidget {
  final void Function(MenuItem item) onItemSelected;
  const AddItemSheet({super.key, required this.onItemSelected});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _menuService = MenuService();
  final _searchController = TextEditingController();
  List<MenuItem> _allItems = [];
  List<MenuItem> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      final items = await _menuService.getMenuItems();
      if (mounted) {
        setState(() {
          _allItems = items.where((i) => i.active).toList();
          _filtered = _allItems;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = _allItems
          .where((i) =>
              i.name.toLowerCase().contains(query.toLowerCase()) ||
              i.yoloClass.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), // Base padding
      height: MediaQuery.of(context).size.height * 0.85, // Fill most of the screen like a standard modal
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Item',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF14142B),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Color(0xFF8F90A6)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF14142B)),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A3BD), fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA0A3BD), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Subtitle
          Text(
            'MENU ITEMS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6E7191),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFfb8500)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Color(0xFFE5E5EA)),
                            const SizedBox(height: 16),
                            Text(
                              'No menu items found.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8F90A6),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFF4F4F6),
                        ),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          return InkWell(
                            onTap: () {
                              widget.onItemSelected(item);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  // Placeholder Image (same style as confirm order)
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
                                          item.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF14142B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RM ${item.price.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFfb8500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFFfb8500),
                                      size: 18,
                                    ),
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
    );
  }
}
