class Restaurant {
  final int id;
  final String name;
  final String address;
  final String phone;
  final bool sstEnabled;
  final double sstRate;
  final bool scEnabled;
  final double scRate;
  final String? imageUrl;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.sstEnabled = false,
    this.sstRate = 6.0,
    this.scEnabled = false,
    this.scRate = 10.0,
    this.imageUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
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
    );
  }
}
