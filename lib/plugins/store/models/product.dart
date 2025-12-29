
class Product {
  final String id;
  final String name;
  final String description;
  final String? image;
  final int stock;
  final int price;
  final DateTime exchangeStart;
  final DateTime exchangeEnd;
  final int useDuration;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.stock,
    required this.price,
    required this.exchangeStart,
    required this.exchangeEnd,
    required this.useDuration,
  });

  // 从JSON创建Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'] as String?,
      stock: json['stock'],
      price: json['price'],
      exchangeStart: DateTime.parse(json['exchange_start']),
      exchangeEnd: DateTime.parse(json['exchange_end']),
      useDuration: json['use_duration'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'stock': stock,
      'price': price,
      'exchange_start': exchangeStart.toIso8601String(),
      'exchange_end': exchangeEnd.toIso8601String(),
      'use_duration': useDuration,
    };
  }
}
