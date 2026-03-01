class MenuItem {
  final int id;
  final String yoloClass;
  final String name;
  final double price;
  final bool active;

  MenuItem({
    required this.id,
    required this.yoloClass,
    required this.name,
    required this.price,
    required this.active,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      yoloClass: json['yolo_class'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] is String
              ? double.tryParse(json['price'])
              : json['price']?.toDouble()) ??
          0.0,
      active: json['active'] ?? true,
    );
  }
}
