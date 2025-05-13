
class UserItem {
  final String id;
  final String productId;
  int remaining;
  final DateTime expireDate;
  final DateTime purchaseDate;
  final int purchasePrice;
  final Map<String, dynamic> productSnapshot;

  UserItem({
    required this.id,
    required this.productId,
    required this.remaining,
    required this.expireDate,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.productSnapshot,
  });

  // 从JSON创建UserItem
  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'],
      productId: json['product_id'],
      remaining: json['remaining'],
      expireDate: DateTime.parse(json['expire_date']),
      purchaseDate: DateTime.parse(json['purchase_date']),
      purchasePrice: json['purchase_price'],
      productSnapshot: Map<String, dynamic>.from(json['product_snapshot']),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'remaining': remaining,
      'expire_date': expireDate.toIso8601String(),
      'purchase_date': purchaseDate.toIso8601String(),
      'purchase_price': purchasePrice,
      'product_snapshot': productSnapshot,
    };
  }

  // 使用物品
  void use() {
    if (remaining > 0) {
      remaining--;
    }
  }

  // 获取商品名称
  String get productName => productSnapshot['name'] ?? '';

  // 获取商品图片
  String get productImage => productSnapshot['image'] ?? '';
}
