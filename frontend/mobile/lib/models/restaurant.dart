class StoreHour {
  final int dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String openTime; // "HH:mm:ss"
  final String closeTime;

  StoreHour({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });

  factory StoreHour.fromJson(Map<String, dynamic> json) {
    return StoreHour(
      dayOfWeek: json['day_of_week'],
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'open_time': openTime,
        'close_time': closeTime,
      };

  static const dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayName => dayNames[dayOfWeek];

  /// Format time like "7:00 AM"
  String get formattedOpen => _formatTime(openTime);
  String get formattedClose => _formatTime(closeTime);

  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$minute $period';
  }
}

class Restaurant {
  final int id;
  final String name;
  final String address;
  final List<StoreHour> storeHours;
  final bool sstEnabled;
  final double sstRate;
  final bool scEnabled;
  final double scRate;
  final String? imageUrl;
  final bool onboardingCompleted;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.storeHours = const [],
    this.sstEnabled = false,
    this.sstRate = 6.0,
    this.scEnabled = false,
    this.scRate = 10.0,
    this.imageUrl,
    this.onboardingCompleted = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      storeHours: (json['store_hours'] as List<dynamic>?)
              ?.map((h) => StoreHour.fromJson(h))
              .toList() ??
          [],
      sstEnabled: json['sst_enabled'] ?? false,
      sstRate: (json['sst_rate'] is String
              ? double.tryParse(json['sst_rate'])
              : json['sst_rate']?.toDouble()) ??
          6.0,
      scEnabled: json['sc_enabled'] ?? false,
      scRate: (json['sc_rate'] is String
              ? double.tryParse(json['sc_rate'])
              : json['sc_rate']?.toDouble()) ??
          10.0,
      imageUrl: json['image_url'],
      onboardingCompleted: json['onboarding_completed'] ?? false,
    );
  }

  /// Human-readable summary of store hours for display
  String get businessHoursSummary {
    if (storeHours.isEmpty) return '';
    // Group consecutive days with same hours
    final sorted = List<StoreHour>.from(storeHours)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    if (sorted.length == 1) {
      final h = sorted.first;
      return '${h.dayName}: ${h.formattedOpen} – ${h.formattedClose}';
    }
    // Check if all have same hours
    final allSame = sorted.every((h) =>
        h.openTime == sorted.first.openTime &&
        h.closeTime == sorted.first.closeTime);
    if (allSame) {
      final h = sorted.first;
      if (sorted.length == 7) {
        return 'Daily ${h.formattedOpen} – ${h.formattedClose}';
      }
      return '${h.formattedOpen} – ${h.formattedClose}';
    }
    return '${sorted.first.formattedOpen} – ${sorted.first.formattedClose}';
  }
}
