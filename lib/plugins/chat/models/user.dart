class User {
  final String id;
  final String username;
  final String? iconPath;

  const User({required this.id, required this.username, this.iconPath});

  /// 将用户信息转换为JSON格式
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'iconPath': iconPath};
  }

  /// 从JSON格式创建User实例
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      iconPath: json['iconPath'] as String?,
    );
  }

  /// 创建一个新的User实例，可选择性地更新某些字段
  User copyWith({
    String? id,
    String? username,
    String? iconPath,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          iconPath == other.iconPath;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ iconPath.hashCode;
}
