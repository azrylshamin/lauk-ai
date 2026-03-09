class Bill {
  final int id;
  final double total;
  final double? subtotal;
  final double sstAmount;
  final double scAmount;
  final DateTime createdAt;
  final int itemCount;
  final List<BillItem>? items;

  Bill({
    required this.id,
    required this.total,
    this.subtotal,
    this.sstAmount = 0.0,
    this.scAmount = 0.0,
    required this.createdAt,
    required this.itemCount,
    this.items,
  });

  bool get hasTaxBreakdown => subtotal != null && (sstAmount > 0 || scAmount > 0);

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      total: _parseDouble(json['total']),
      subtotal: json['subtotal'] != null ? _parseDouble(json['subtotal']) : null,
      sstAmount: json['sst_amount'] != null ? _parseDouble(json['sst_amount']) : 0.0,
      scAmount: json['sc_amount'] != null ? _parseDouble(json['sc_amount']) : 0.0,
      createdAt: DateTime.parse(json['created_at']),
      itemCount: json['item_count'] ?? (json['items'] as List?)?.length ?? 0,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => BillItem.fromJson(i)).toList()
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is String) return double.tryParse(value) ?? 0.0;
    return value?.toDouble() ?? 0.0;
  }
}

class BillItem {
  final int id;
  final String name;
  final double price;
  final int quantity;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'],
      name: json['name'] ?? '',
      price: (json['price'] is String
              ? double.tryParse(json['price'])
              : json['price']?.toDouble()) ??
          0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

class BillStats {
  final int billCount;
  final double revenue;
  final double average;
  final double? accuracy;
  final double? revenueGrowth;
  final String? topItem;
  final List<Bill> recentTransactions;

  BillStats({
    required this.billCount,
    required this.revenue,
    required this.average,
    this.accuracy,
    this.revenueGrowth,
    this.topItem,
    this.recentTransactions = const [],
  });

  factory BillStats.fromJson(Map<String, dynamic> json) {
    return BillStats(
      billCount: json['billCount'] ?? 0,
      revenue: (json['revenue'] is String
              ? double.tryParse(json['revenue'])
              : json['revenue']?.toDouble()) ??
          0.0,
      average: (json['average'] is String
              ? double.tryParse(json['average'])
              : json['average']?.toDouble()) ??
          0.0,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] is String
              ? double.tryParse(json['accuracy'])
              : json['accuracy']?.toDouble())
          : null,
      revenueGrowth: json['revenueGrowth'] != null
          ? (json['revenueGrowth'] is String
              ? double.tryParse(json['revenueGrowth'])
              : json['revenueGrowth']?.toDouble())
          : null,
      topItem: json['topItem'],
      recentTransactions: json['recentTransactions'] != null
          ? (json['recentTransactions'] as List)
              .map((b) => Bill.fromJson(b))
              .toList()
          : [],
    );
  }
}
