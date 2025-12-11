import 'dart:convert';

/// 用户注册请求
class RegisterRequest {
  /// 用户名 (通常是邮箱)
  final String username;

  /// 密码 (明文，传输时应使用 HTTPS)
  final String password;

  /// 设备名称
  final String? deviceName;

  /// 设备 ID
  final String deviceId;

  RegisterRequest({
    required this.username,
    required this.password,
    this.deviceName,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'device_name': deviceName,
        'device_id': deviceId,
      };

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      RegisterRequest(
        username: json['username'] as String,
        password: json['password'] as String,
        deviceName: json['device_name'] as String?,
        deviceId: json['device_id'] as String,
      );
}

/// 用户登录请求
class LoginRequest {
  /// 用户名
  final String username;

  /// 密码
  final String password;

  /// 设备名称
  final String? deviceName;

  /// 设备 ID
  final String deviceId;

  LoginRequest({
    required this.username,
    required this.password,
    this.deviceName,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'device_name': deviceName,
        'device_id': deviceId,
      };

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
        username: json['username'] as String,
        password: json['password'] as String,
        deviceName: json['device_name'] as String?,
        deviceId: json['device_id'] as String,
      );
}

/// 认证响应
class AuthResponse {
  /// 是否成功
  final bool success;

  /// 用户 ID
  final String? userId;

  /// JWT Token
  final String? token;

  /// Token 过期时间
  final DateTime? expiresAt;

  /// 用户 Salt (用于客户端派生加密密钥)
  final String? userSalt;

  /// 错误消息
  final String? error;

  AuthResponse({
    required this.success,
    this.userId,
    this.token,
    this.expiresAt,
    this.userSalt,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'user_id': userId,
        'token': token,
        'expires_at': expiresAt?.toIso8601String(),
        'user_salt': userSalt,
        'error': error,
      };

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        success: json['success'] as bool,
        userId: json['user_id'] as String?,
        token: json['token'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        userSalt: json['user_salt'] as String?,
        error: json['error'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AuthResponse.fromJsonString(String jsonString) =>
      AuthResponse.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  /// 创建成功响应
  factory AuthResponse.success({
    required String userId,
    required String token,
    required DateTime expiresAt,
    required String userSalt,
  }) =>
      AuthResponse(
        success: true,
        userId: userId,
        token: token,
        expiresAt: expiresAt,
        userSalt: userSalt,
      );

  /// 创建失败响应
  factory AuthResponse.failure(String error) => AuthResponse(
        success: false,
        error: error,
      );
}

/// 用户信息模型 (服务器存储)
class UserInfo {
  /// 用户 ID
  final String id;

  /// 用户名
  final String username;

  /// 密码哈希 (SHA256)
  final String passwordHash;

  /// 用户 Salt (用于加密密钥派生)
  final String salt;

  /// 创建时间
  final DateTime createdAt;

  /// 最后登录时间
  final DateTime? lastLoginAt;

  /// 已注册设备列表
  final List<DeviceInfo> devices;

  UserInfo({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.lastLoginAt,
    this.devices = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
        'devices': devices.map((d) => d.toJson()).toList(),
      };

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['id'] as String,
        username: json['username'] as String,
        passwordHash: json['password_hash'] as String,
        salt: json['salt'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'] as String)
            : null,
        devices: json['devices'] != null
            ? (json['devices'] as List)
                .map((d) => DeviceInfo.fromJson(d as Map<String, dynamic>))
                .toList()
            : [],
      );

  /// 复制并更新部分字段
  UserInfo copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? salt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<DeviceInfo>? devices,
  }) =>
      UserInfo(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        devices: devices ?? this.devices,
      );
}

/// 设备信息
class DeviceInfo {
  /// 设备 ID
  final String deviceId;

  /// 设备名称
  final String? deviceName;

  /// 最后同步时间
  final DateTime? lastSyncAt;

  /// 注册时间
  final DateTime createdAt;

  DeviceInfo({
    required this.deviceId,
    this.deviceName,
    this.lastSyncAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'last_sync_at': lastSyncAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String?,
        lastSyncAt: json['last_sync_at'] != null
            ? DateTime.parse(json['last_sync_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Token 刷新请求
class RefreshTokenRequest {
  /// 当前 Token
  final String token;

  /// 设备 ID
  final String deviceId;

  RefreshTokenRequest({
    required this.token,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'device_id': deviceId,
      };

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      RefreshTokenRequest(
        token: json['token'] as String,
        deviceId: json['device_id'] as String,
      );
}
