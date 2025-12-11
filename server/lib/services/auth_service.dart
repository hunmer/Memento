import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_models/shared_models.dart';

import 'file_storage_service.dart';

/// 认证服务 - JWT Token 管理和用户认证
class AuthService {
  final FileStorageService _storageService;
  final String _jwtSecret;
  final int _tokenExpiryDays;
  final _uuid = const Uuid();

  AuthService({
    required FileStorageService storageService,
    required String jwtSecret,
    int tokenExpiryDays = 36500, // 100年 = 永久有效
  })  : _storageService = storageService,
        _jwtSecret = jwtSecret,
        _tokenExpiryDays = tokenExpiryDays;

  /// 注册新用户
  Future<AuthResponse> register(RegisterRequest request) async {
    // 检查用户名是否已存在
    final existingUser =
        await _storageService.findUserByUsername(request.username);
    if (existingUser != null) {
      return AuthResponse.failure('用户名已存在');
    }

    // 生成用户 Salt (用于客户端加密密钥派生)
    final userSalt = PasswordHashUtils.generateSalt();

    // 生成密码哈希 (用于服务器验证)
    final passwordHash =
        PasswordHashUtils.hashPassword(request.password, userSalt);

    // 创建用户
    final userId = _uuid.v4();
    final now = DateTime.now();

    final user = UserInfo(
      id: userId,
      username: request.username,
      passwordHash: passwordHash,
      salt: userSalt,
      createdAt: now,
      devices: [
        DeviceInfo(
          deviceId: request.deviceId,
          deviceName: request.deviceName,
          createdAt: now,
        ),
      ],
    );

    // 保存用户
    await _storageService.addUser(user);

    // 生成 Token
    final token = _generateToken(userId);
    final expiresAt = DateTime.now().add(Duration(days: _tokenExpiryDays));

    return AuthResponse.success(
      userId: userId,
      token: token,
      expiresAt: expiresAt,
      userSalt: userSalt,
    );
  }

  /// 用户登录
  Future<AuthResponse> login(LoginRequest request) async {
    // 查找用户
    final user = await _storageService.findUserByUsername(request.username);
    if (user == null) {
      return AuthResponse.failure('用户名或密码错误');
    }

    // 验证密码
    if (!PasswordHashUtils.verifyPassword(
        request.password, user.salt, user.passwordHash)) {
      return AuthResponse.failure('用户名或密码错误');
    }

    // 更新设备信息
    final now = DateTime.now();
    final deviceIndex =
        user.devices.indexWhere((d) => d.deviceId == request.deviceId);

    List<DeviceInfo> updatedDevices;
    if (deviceIndex >= 0) {
      // 更新现有设备
      updatedDevices = [...user.devices];
      updatedDevices[deviceIndex] = DeviceInfo(
        deviceId: request.deviceId,
        deviceName: request.deviceName ?? user.devices[deviceIndex].deviceName,
        lastSyncAt: now,
        createdAt: user.devices[deviceIndex].createdAt,
      );
    } else {
      // 添加新设备
      updatedDevices = [
        ...user.devices,
        DeviceInfo(
          deviceId: request.deviceId,
          deviceName: request.deviceName,
          createdAt: now,
        ),
      ];
    }

    // 更新用户信息
    final updatedUser = user.copyWith(
      lastLoginAt: now,
      devices: updatedDevices,
    );
    await _storageService.updateUser(updatedUser);

    // 生成 Token
    final token = _generateToken(user.id);
    final expiresAt = DateTime.now().add(Duration(days: _tokenExpiryDays));

    return AuthResponse.success(
      userId: user.id,
      token: token,
      expiresAt: expiresAt,
      userSalt: user.salt,
    );
  }

  /// 刷新 Token
  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    // 验证当前 Token
    final payload = verifyToken(request.token);
    if (payload == null) {
      return AuthResponse.failure('Token 无效或已过期');
    }

    final userId = payload['sub'] as String?;
    if (userId == null) {
      return AuthResponse.failure('Token 格式错误');
    }

    // 查找用户
    final user = await _storageService.findUserById(userId);
    if (user == null) {
      return AuthResponse.failure('用户不存在');
    }

    // 生成新 Token
    final newToken = _generateToken(userId);
    final expiresAt = DateTime.now().add(Duration(days: _tokenExpiryDays));

    return AuthResponse.success(
      userId: userId,
      token: newToken,
      expiresAt: expiresAt,
      userSalt: user.salt,
    );
  }

  /// 验证 Token
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 从 Token 获取用户 ID
  String? getUserIdFromToken(String token) {
    final payload = verifyToken(token);
    return payload?['sub'] as String?;
  }

  /// 生成 JWT Token
  String _generateToken(String userId) {
    final jwt = JWT(
      {
        'sub': userId,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now()
                .add(Duration(days: _tokenExpiryDays))
                .millisecondsSinceEpoch ~/
            1000,
      },
    );

    return jwt.sign(SecretKey(_jwtSecret));
  }
}
