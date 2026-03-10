import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _MenuItemEntry {
  final String yoloClass;
  final IconData icon;
  bool enabled;
  final TextEditingController nameController;
  final TextEditingController priceController;

  _MenuItemEntry({
    required this.yoloClass,
    required this.icon,
    required String defaultName,
    required String defaultPrice,
  })  : enabled = true,
        nameController = TextEditingController(text: defaultName),
        priceController = TextEditingController(text: defaultPrice);

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _primaryColor = Color(0xFFFF8A00);
  static const _textColor = Color(0xFF14171F);
  static const _subtitleColor = Color(0xFF6B7280);
  static const _bgColor = Color(0xFFF9FAFB);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _totalSteps = 5;

  final _pageController = PageController();
  final _restaurantService = RestaurantService();
  final _menuService = MenuService();
  final _authService = AuthService();

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sstRateController = TextEditingController(text: '6.0');
  final _scRateController = TextEditingController(text: '10.0');

  int _currentStep = 0;
  bool _sstEnabled = false;
  bool _scEnabled = false;
  String? _imageUrl;
  bool _saving = false;
  bool _uploading = false;

  // Staff invite state
  final _staffNameController = TextEditingController();
  final _staffEmailController = TextEditingController();
  final _staffPasswordController = TextEditingController();
  bool _inviting = false;
  String? _inviteError;
  final List<Map<String, String>> _invitedStaff = [];

  late final List<_MenuItemEntry> _menuItems = [
    _MenuItemEntry(
        yoloClass: 'Chicken',
        icon: Icons.set_meal,
        defaultName: 'Ayam',
        defaultPrice: '8.00'),
    _MenuItemEntry(
        yoloClass: 'Fish',
        icon: Icons.water,
        defaultName: 'Ikan',
        defaultPrice: '10.00'),
    _MenuItemEntry(
        yoloClass: 'Rice',
        icon: Icons.rice_bowl,
        defaultName: 'Nasi',
        defaultPrice: '3.00'),
    _MenuItemEntry(
        yoloClass: 'Egg',
        icon: Icons.egg,
        defaultName: 'Telur',
        defaultPrice: '2.00'),
    _MenuItemEntry(
        yoloClass: 'Vegetables',
        icon: Icons.eco,
        defaultName: 'Sayur',
        defaultPrice: '4.00'),
    _MenuItemEntry(
        yoloClass: 'Sauce',
        icon: Icons.soup_kitchen,
        defaultName: 'Kuah',
        defaultPrice: '1.00'),
  ];

  final _stepTitles = const [
    'Restaurant Photo',
    'Restaurant Details',
    'Menu Items',
    'Tax & Charges',
    'Invite Staff',
  ];

  final _stepSubtitles = const [
    'Make a great first impression',
    'Help customers find your restaurant',
    'Set up your menu for AI prediction',
    'Configure your tax and service charge rates',
    'Add your team members to get started',
  ];

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _skipOnboarding() async {
    setState(() => _saving = true);
    try {
      await _restaurantService.updateProfile({'onboarding_completed': true});
    } catch (_) {
      // Still navigate even if the API call fails
    }
    if (mounted) {
      context.read<AuthProvider>().clearOnboardingFlag();
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _saving = true);
    try {
      // Save restaurant profile
      await _restaurantService.updateProfile({
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'sst_enabled': _sstEnabled,
        'sst_rate': double.tryParse(_sstRateController.text) ?? 6.0,
        'sc_enabled': _scEnabled,
        'sc_rate': double.tryParse(_scRateController.text) ?? 10.0,
        'onboarding_completed': true,
      });

      // Create enabled menu items
      for (final item in _menuItems) {
        if (!item.enabled) continue;
        final name = item.nameController.text.trim();
        final price = double.tryParse(item.priceController.text);
        if (name.isEmpty || price == null) continue;
        try {
          await _menuService.createMenuItem(item.yoloClass, name, price);
        } catch (_) {
          // Skip items that fail (e.g. duplicates)
        }
      }

      if (mounted) {
        context.read<AuthProvider>().clearOnboardingFlag();
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final r = await _restaurantService.uploadImage(picked.path);
      if (mounted) {
        setState(() {
          _imageUrl = r.imageUrl;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _sstRateController.dispose();
    _scRateController.dispose();
    for (final item in _menuItems) {
      item.dispose();
    }
    _staffNameController.dispose();
    _staffEmailController.dispose();
    _staffPasswordController.dispose();
    super.dispose();
  }

  // --- Reusable widgets ---

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: _textColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(
              color: _textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(
                color: const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w500),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
        ),
      ],
    );
  }

  Widget _buildTaxRow({
    required String label,
    required bool enabled,
    required TextEditingController rateController,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeTrackColor: _primaryColor,
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
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  borderSide: const BorderSide(color: _primaryColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step pages ---

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            hintText: 'Enter your restaurant address',
            controller: _addressController,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Phone Number',
            hintText: 'Enter phone number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _uploading ? null : _pickAndUploadImage,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: 2),
                image: _imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _uploading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : _imageUrl == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: GoogleFonts.inter(
                                color: _subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : null,
            ),
          ),
          if (_imageUrl != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _uploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Change Photo'),
              style: TextButton.styleFrom(foregroundColor: _primaryColor),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Optional — you can add this later in Settings',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildTaxRow(
            label: 'SST',
            enabled: _sstEnabled,
            rateController: _sstRateController,
            onToggle: (val) => setState(() => _sstEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildTaxRow(
            label: 'Service Charge',
            enabled: _scEnabled,
            rateController: _scRateController,
            onToggle: (val) => setState(() => _scEnabled = val),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: _primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can always change these later in Settings.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF92400E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuStep() {
    final enabledCount = _menuItems.where((e) => e.enabled).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            '$enabledCount of 6 items selected',
            style: GoogleFonts.inter(
              color: _subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ..._menuItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMenuItemCard(item),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: _primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These are needed for AI food prediction. You can edit them later in the Menu tab.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF92400E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(_MenuItemEntry item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.enabled ? Colors.white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.enabled ? _primaryColor.withValues(alpha: 0.4) : _borderColor,
          width: item.enabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Toggle + icon
          GestureDetector(
            onTap: () => setState(() => item.enabled = !item.enabled),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.enabled
                    ? _primaryColor.withValues(alpha: 0.1)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.enabled ? _primaryColor : Colors.grey[400],
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + class label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.yoloClass,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.enabled ? _primaryColor : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: item.nameController,
                    enabled: item.enabled,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor:
                          item.enabled ? Colors.white : const Color(0xFFF3F4F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: item.enabled ? _subtitleColor : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                height: 36,
                child: TextField(
                  controller: item.priceController,
                  enabled: item.enabled,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: item.enabled ? _primaryColor : Colors.grey[400],
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor:
                        item.enabled ? Colors.white : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Checkbox
          GestureDetector(
            onTap: () => setState(() => item.enabled = !item.enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.enabled ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.enabled ? _primaryColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: item.enabled
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // --- Staff invite ---

  Future<void> _inviteStaff() async {
    final name = _staffNameController.text.trim();
    final email = _staffEmailController.text.trim();
    final password = _staffPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _inviteError = 'Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      setState(() => _inviteError = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _inviting = true;
      _inviteError = null;
    });

    try {
      await _authService.invite(name, email, password);
      if (mounted) {
        setState(() {
          _invitedStaff.add({'name': name, 'email': email});
          _staffNameController.clear();
          _staffEmailController.clear();
          _staffPasswordController.clear();
          _inviting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inviteError = e.toString();
          _inviting = false;
        });
      }
    }
  }

  Widget _buildStaffStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Invite form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  label: 'Staff Name',
                  hintText: 'Enter staff name',
                  controller: _staffNameController,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  label: 'Email',
                  hintText: 'Enter staff email',
                  controller: _staffEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  label: 'Temporary Password',
                  hintText: 'Min. 6 characters',
                  controller: _staffPasswordController,
                  textInputAction: TextInputAction.done,
                ),
                if (_inviteError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _inviteError!,
                    style: GoogleFonts.inter(
                        color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _inviting ? null : _inviteStaff,
                    icon: _inviting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_outlined, size: 18),
                    label: Text(
                      _inviting ? 'Inviting...' : 'Add Staff Member',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Invited staff list
          if (_invitedStaff.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Invited (${_invitedStaff.length})',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 10),
            ..._invitedStaff.map((staff) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            staff['name']![0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['name']!,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _textColor,
                              ),
                            ),
                            Text(
                              staff['email']!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF16A34A), size: 20),
                    ],
                  ),
                )),
          ],

          if (_invitedStaff.isEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: _primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Optional — you can invite staff later in Settings.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF92400E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Step indicator ---

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? _primaryColor
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo and step info
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.restaurant_menu,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: GoogleFonts.inter(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _stepTitles[_currentStep],
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _stepSubtitles[_currentStep],
                  style: GoogleFonts.inter(
                    color: _subtitleColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPhotoStep(),
                    _buildDetailsStep(),
                    _buildMenuStep(),
                    _buildTaxStep(),
                    _buildStaffStep(),
                  ],
                ),
              ),

              // Bottom buttons
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: _subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          onPressed: _saving ? null : _goBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: const BorderSide(color: _primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : (isLastStep ? _completeOnboarding : _goNext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLastStep ? 'Finish' : 'Next',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
