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
      setState(() {
        _allItems = items.where((i) => i.active).toList();
        _filtered = _allItems;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Item',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search menu...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final item = _filtered[index];
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Text(item.yoloClass,
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12)),
                                trailing: Text(
                                    'RM ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                onTap: () {
                                  widget.onItemSelected(item);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
