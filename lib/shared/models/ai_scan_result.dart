class AiScanResult {
  final String? store;
  final String? date;
  final double? total;
  final String? suggestedCategory;
  final String? type;
  final List<ReceiptItem>? items;

  AiScanResult({
    this.store,
    this.date,
    this.total,
    this.suggestedCategory,
    this.type,
    this.items,
  });

  factory AiScanResult.fromJson(Map<String, dynamic> json) {
    return AiScanResult(
      store: json['store'] as String?,
      date: json['date'] as String?,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      suggestedCategory: json['suggestedCategory'] as String?,
      type: json['type'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}
