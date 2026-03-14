import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../services/restaurant_service.dart';

class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _DayEntry {
  final int dayOfWeek;
  bool enabled;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  _DayEntry({
    required this.dayOfWeek,
    this.enabled = false,
    this.openTime = const TimeOfDay(hour: 8, minute: 0),
    this.closeTime = const TimeOfDay(hour: 21, minute: 0),
  });

  String get dayName => StoreHour.dayNames[dayOfWeek];
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  final _restaurantService = RestaurantService();
  bool _loading = true;
  bool _saving = false;

  late final List<_DayEntry> _days = List.generate(
    7,
    (i) => _DayEntry(dayOfWeek: i),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _restaurantService.getProfile();
      for (final h in r.storeHours) {
        final day = _days[h.dayOfWeek];
        day.enabled = true;
        day.openTime = _parseTime(h.openTime);
        day.closeTime = _parseTime(h.closeTime);
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTimeForApi(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeDisplay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(_DayEntry day, bool isOpen) async {
    final initial = isOpen ? day.openTime : day.closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          day.openTime = picked;
        } else {
          day.closeTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final hours = _days
          .where((d) => d.enabled)
          .map((d) => StoreHour(
                dayOfWeek: d.dayOfWeek,
                openTime: _formatTimeForApi(d.openTime),
                closeTime: _formatTimeForApi(d.closeTime),
              ))
          .toList();

      await _restaurantService.updateStoreHours(hours);

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business hours updated!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB8500).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time,
                        size: 40,
                        color: Color(0xFFFB8500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Set your operating hours',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14142B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Toggle each day and set open/close times.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Day rows
                  ..._days.map((day) => _buildDayRow(day, isOwner)),

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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  if (!isOwner) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Only the owner can edit business hours.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDayRow(_DayEntry day, bool isOwner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: day.enabled ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.enabled
              ? const Color(0xFFFB8500).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Switch(
              value: day.enabled,
              onChanged: isOwner
                  ? (val) => setState(() => day.enabled = val)
                  : null,
              activeTrackColor: const Color(0xFFFB8500),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              day.dayName.substring(0, 3),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: day.enabled
                    ? const Color(0xFF14142B)
                    : Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (day.enabled) ...[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildTimeChip(
                    _formatTimeDisplay(day.openTime),
                    isOwner ? () => _pickTime(day, true) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold)),
                  ),
                  _buildTimeChip(
                    _formatTimeDisplay(day.closeTime),
                    isOwner ? () => _pickTime(day, false) : null,
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'Closed',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}
