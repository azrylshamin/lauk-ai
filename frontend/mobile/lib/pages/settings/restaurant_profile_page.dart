import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';

class RestaurantProfilePage extends StatefulWidget {
  const RestaurantProfilePage({super.key});

  @override
  State<RestaurantProfilePage> createState() => _RestaurantProfilePageState();
}

class _RestaurantProfilePageState extends State<RestaurantProfilePage> {
  final _restaurantService = RestaurantService();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  final _sstRateController = TextEditingController();
  final _scRateController = TextEditingController();
  bool _sstEnabled = false;
  bool _scEnabled = false;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _restaurantService.getProfile();
      _nameController.text = r.name;
      _addressController.text = r.address;

      _sstEnabled = r.sstEnabled;
      _scEnabled = r.scEnabled;
      _sstRateController.text = r.sstRate.toString();
      _scRateController.text = r.scRate.toString();
      _imageUrl = r.imageUrl;
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final r = await _restaurantService.uploadImage(picked.path);
      if (mounted) {
        setState(() {
          _imageUrl = r.imageUrl;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    setState(() => _saving = true);
    try {
      await _restaurantService.deleteImage();
      if (mounted) {
        setState(() {
          _imageUrl = null;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove image: $e')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Change Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[600]),
              title: Text('Remove Photo',
                  style: TextStyle(color: Colors.red[600])),
              onTap: () {
                Navigator.pop(ctx);
                _deleteImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isOwner) return;

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _restaurantService.updateProfile({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'sst_enabled': _sstEnabled,
        'sst_rate': double.tryParse(_sstRateController.text) ?? 6.0,
        'sc_enabled': _scEnabled,
        'sc_rate': double.tryParse(_scRateController.text) ?? 10.0,
      });
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Profile updated!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant profile updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Failed to update';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _sstRateController.dispose();
    _scRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Restaurant'),
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Restaurant Image
                  Center(
                    child: GestureDetector(
                      onTap: isOwner
                          ? (_imageUrl != null
                              ? _showImageOptions
                              : _pickAndUploadImage)
                          : null,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          image: _imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant,
                                      size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOwner ? 'Add Photo' : 'No Photo',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Restaurant Name'),
                    enabled: isOwner,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    enabled: isOwner,
                  ),
                  const SizedBox(height: 32),

                  // Tax & Charges Section
                  Text(
                    'Tax & Charges',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14142B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SST Row
                  _buildTaxRow(
                    label: 'SST',
                    enabled: _sstEnabled,
                    rateController: _sstRateController,
                    isOwner: isOwner,
                    onToggle: (val) => setState(() => _sstEnabled = val),
                  ),
                  const SizedBox(height: 12),

                  // Service Charge Row
                  _buildTaxRow(
                    label: 'Service Charge',
                    enabled: _scEnabled,
                    rateController: _scRateController,
                    isOwner: isOwner,
                    onToggle: (val) => setState(() => _scEnabled = val),
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message == 'Profile updated!' ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (isOwner)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFB8500),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  if (!isOwner) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Only the owner can edit the restaurant profile.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTaxRow({
    required String label,
    required bool enabled,
    required TextEditingController rateController,
    required bool isOwner,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Switch(
            value: enabled,
            onChanged: isOwner ? onToggle : null,
            activeTrackColor: const Color(0xFFFB8500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF14142B),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: rateController,
              enabled: isOwner && enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6E7191),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFB8500)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
