class ReceiptItem {
  final String name;
  final double price;

  ReceiptItem({
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
} 