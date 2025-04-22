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
}
