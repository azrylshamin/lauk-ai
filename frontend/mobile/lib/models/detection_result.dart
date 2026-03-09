class DetectionItem {
  String name;
  final String yoloClass;
  double? price;
  final double confidence;
  final bool known;
  int? menuItemId;
  int quantity;

  DetectionItem({
    required this.name,
    required this.yoloClass,
    this.price,
    required this.confidence,
    required this.known,
    this.menuItemId,
    this.quantity = 1,
  });

  factory DetectionItem.fromJson(Map<String, dynamic> json) {
    return DetectionItem(
      name: json['name'] ?? json['yolo_class'] ?? 'Unknown',
      yoloClass: json['yolo_class'] ?? '',
      price: json['price'] != null
          ? (json['price'] is String
              ? double.tryParse(json['price'])
              : json['price']?.toDouble())
          : null,
      confidence: (json['confidence'] is String
              ? double.tryParse(json['confidence'])
              : json['confidence']?.toDouble()) ??
          0.0,
      known: json['known'] ?? false,
      menuItemId: json['menu_item_id'],
      quantity: 1,
    );
  }

  bool get isUnknown => !known || price == null;

  double get subtotal => (price ?? 0) * quantity;
}

class DetectionResult {
  final List<DetectionItem> items;
  final double total;
  final double? subtotal;
  final double sstAmount;
  final double scAmount;
  final int count;

  DetectionResult({
    required this.items,
    required this.total,
    this.subtotal,
    this.sstAmount = 0.0,
    this.scAmount = 0.0,
    required this.count,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      items: (json['items'] as List)
          .map((i) => DetectionItem.fromJson(i))
          .toList(),
      total: (json['total'] is String
              ? double.tryParse(json['total'])
              : json['total']?.toDouble()) ??
          0.0,
      subtotal: json['subtotal'] != null
          ? (json['subtotal'] is String
              ? double.tryParse(json['subtotal'])
              : json['subtotal']?.toDouble())
          : null,
      sstAmount: json['sst_amount'] != null
          ? (json['sst_amount'] is String
              ? double.tryParse(json['sst_amount'])
              : json['sst_amount']?.toDouble()) ?? 0.0
          : 0.0,
      scAmount: json['sc_amount'] != null
          ? (json['sc_amount'] is String
              ? double.tryParse(json['sc_amount'])
              : json['sc_amount']?.toDouble()) ?? 0.0
          : 0.0,
      count: json['count'] ?? 0,
    );
  }
}
