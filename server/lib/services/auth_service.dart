import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_models/shared_models.dart';

import 'file_storage_service.dart';
import '../models/api_key.dart';

/// 认证服务 - JWT Token 管理和用户认证
class AuthService {
  final FileStorageService _storageService;
  final String _jwtSecret;
  final int _tokenExpiryDays;
  final _uuid = const Uuid();

  /// API Key 存储管理
  late final ApiKeyStore _apiKeyStore;

  AuthService({
    required FileStorageService storageService,
    required String jwtSecret,
    required String dataDir,
    int tokenExpiryDays = 36500, // 100年 = 永久有效
  })  : _storageService = storageService,
        _jwtSecret = jwtSecret,
        _tokenExpiryDays = tokenExpiryDays {
    _apiKeyStore = ApiKeyStore(dataDir);
  }

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

  // ==================== API Key 管理 ====================

  /// 生成新的 API Key
  ///
  /// API Key 用于代替用户名密码进行认证
  /// 加密密钥通过 X-Encryption-Key 请求头传递，不存储在 API Key 中
  Future<ApiKey> generateApiKey({
    required String userId,
    required String name,
    ApiKeyExpiry expiry = ApiKeyExpiry.never,
  }) async {
    // 验证用户存在
    final user = await _storageService.findUserById(userId);
    if (user == null) {
      throw Exception('用户不存在');
    }

    // 生成 API Key
    final apiKey = ApiKey.generate(
      userId: userId,
      name: name,
      expiry: expiry,
    );

    // 保存到存储
    await _apiKeyStore.saveKey(apiKey);

    return apiKey;
  }

  /// 验证 API Key
  ///
  /// 返回验证结果，包含用户 ID
  /// 如果验证失败返回 null
  Future<ApiKeyValidationResult?> verifyApiKey(String keyValue) async {
    final apiKey = await _apiKeyStore.findByKey(keyValue);

    if (apiKey == null) {
      return null;
    }

    // 检查是否过期
    if (apiKey.isExpired) {
      return null;
    }

    // 更新最后使用时间
    await _apiKeyStore.updateLastUsed(keyValue);

    return ApiKeyValidationResult(
      userId: apiKey.userId,
      keyId: apiKey.id,
      keyName: apiKey.name,
    );
  }

  /// 获取用户的所有 API Keys
  Future<List<ApiKey>> listApiKeys(String userId) async {
    return await _apiKeyStore.findByUserId(userId);
  }

  /// 撤销 API Key
  Future<bool> revokeApiKey(String userId, String keyId) async {
    final keys = await _apiKeyStore.findByUserId(userId);
    final key = keys.firstWhere(
      (k) => k.id == keyId,
      orElse: () => throw Exception('API Key 不存在'),
    );

    if (key.userId != userId) {
      throw Exception('无权操作此 API Key');
    }

    return await _apiKeyStore.deleteKey(keyId);
  }
}

/// API Key 验证结果
class ApiKeyValidationResult {
  final String userId;
  final String keyId;
  final String keyName;

  ApiKeyValidationResult({
    required this.userId,
    required this.keyId,
    required this.keyName,
  });
}
