
class UserItem {
  final String id;
  final String productId;
  int remaining;
  final DateTime expireDate;

  UserItem({
    required this.id,
    required this.productId,
    required this.remaining,
    required this.expireDate,
  });

  // 从JSON创建UserItem
  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'],
      productId: json['product_id'],
      remaining: json['remaining'],
      expireDate: DateTime.parse(json['expire_date']),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'remaining': remaining,
      'expire_date': expireDate.toIso8601String(),
    };
  }

  // 使用物品
  void use() {
    if (remaining > 0) {
      remaining--;
    }
  }
}
