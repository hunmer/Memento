import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../services/auth_service.dart';
import '../services/plugin_data_service.dart';
import '../models/api_key.dart';

/// 认证路由
///
/// 安全说明：加密密钥只保存在内存中，不持久化到文件
/// 每次请求需要通过请求头 X-Encryption-Key 传递密钥
class AuthRoutes {
  final AuthService _authService;
  final PluginDataService? _pluginDataService;

  AuthRoutes(this._authService, [this._pluginDataService]);

  Router get router {
    final router = Router();

    // POST /register - 用户注册
    router.post('/register', _handleRegister);

    // POST /login - 用户登录
    router.post('/login', _handleLogin);

    // POST /refresh - 刷新 Token
    router.post('/refresh', _handleRefresh);

    // POST /set-encryption-key - 设置加密密钥（仅内存）
    router.post('/set-encryption-key', _handleSetEncryptionKey);

    // POST /clear-encryption-key - 清除内存中的加密密钥
    router.post('/clear-encryption-key', _handleClearEncryptionKey);

    // GET /has-encryption-key - 检查是否已设置密钥（仅内存）
    router.get('/has-encryption-key', _handleHasEncryptionKey);

    // POST /re-encrypt - 用新密钥重新加密所有文件
    router.post('/re-encrypt', _handleReEncrypt);

    // ==================== API Key 管理 ====================

    // POST /api-keys - 创建 API Key (需要认证)
    router.post('/api-keys', _handleCreateApiKey);

    // GET /api-keys - 列出用户的 API Keys (需要认证)
    router.get('/api-keys', _handleListApiKeys);

    // DELETE /api-keys/<id> - 撤销 API Key (需要认证)
    router.delete('/api-keys/<id>', _handleRevokeApiKey);

    return router;
  }

  /// 处理用户注册
  Future<Response> _handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 验证必填字段
      if (data['username'] == null || data['password'] == null) {
        return _errorResponse(400, '用户名和密码不能为空');
      }

      if ((data['username'] as String).length < 3) {
        return _errorResponse(400, '用户名至少需要 3 个字符');
      }

      if ((data['password'] as String).length < 6) {
        return _errorResponse(400, '密码至少需要 6 个字符');
      }

      if (data['device_id'] == null) {
        return _errorResponse(400, '设备 ID 不能为空');
      }

      final registerRequest = RegisterRequest.fromJson(data);
      final response = await _authService.register(registerRequest);

      if (response.success) {
        return Response.ok(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return _errorResponse(400, response.error ?? '注册失败');
      }
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理用户登录
  Future<Response> _handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 验证必填字段
      if (data['username'] == null || data['password'] == null) {
        return _errorResponse(400, '用户名和密码不能为空');
      }

      if (data['device_id'] == null) {
        return _errorResponse(400, '设备 ID 不能为空');
      }

      final loginRequest = LoginRequest.fromJson(data);
      final response = await _authService.login(loginRequest);

      if (response.success) {
        return Response.ok(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return _errorResponse(401, response.error ?? '登录失败');
      }
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理 Token 刷新
  Future<Response> _handleRefresh(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['token'] == null || data['device_id'] == null) {
        return _errorResponse(400, 'Token 和设备 ID 不能为空');
      }

      final refreshRequest = RefreshTokenRequest.fromJson(data);
      final response = await _authService.refreshToken(refreshRequest);

      if (response.success) {
        return Response.ok(
          response.toJsonString(),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return _errorResponse(401, response.error ?? '刷新失败');
      }
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 生成错误响应
  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 从请求头获取并验证 Token，返回 userId
  String? _getUserIdFromRequest(Request request) {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    return _authService.getUserIdFromToken(token);
  }

  /// 设置加密密钥（仅内存，不持久化）
  ///
  /// 请求体: { "encryption_key": "base64-encoded-key" }
  Future<Response> _handleSetEncryptionKey(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final encryptionKey = data['encryption_key'] as String?;
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return _errorResponse(400, '缺少 encryption_key 参数');
      }

      // 验证密钥格式
      try {
        _pluginDataService!.setEncryptionKey(userId, encryptionKey);
      } catch (e) {
        return _errorResponse(400, '无效的加密密钥: $e');
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': '加密密钥已设置（仅当前会话有效）',
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 清除内存中的加密密钥
  Future<Response> _handleClearEncryptionKey(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      _pluginDataService!.removeEncryptionKey(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': '加密密钥已清除',
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 检查是否已设置密钥（仅内存）
  Future<Response> _handleHasEncryptionKey(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      final hasKey = _pluginDataService!.hasEncryptionKey(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'has_key': hasKey,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 重新加密所有文件
  ///
  /// 请求体: { "old_key": "base64-old-key", "new_key": "base64-new-key" }
  Future<Response> _handleReEncrypt(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final oldKey = data['old_key'] as String?;
      final newKey = data['new_key'] as String?;

      if (oldKey == null || newKey == null) {
        return _errorResponse(400, '缺少 old_key 或 new_key 参数');
      }

      // 先设置旧密钥
      _pluginDataService!.setEncryptionKey(userId, oldKey);

      // 执行重新加密
      final result = await _pluginDataService!.reEncryptAllFiles(userId, newKey);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': '重新加密完成',
          'files_re_encrypted': result['file_count'],
          'errors': result['errors'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '重新加密失败: $e');
    }
  }

  // ==================== API Key 管理 ====================

  /// 处理创建 API Key
  Future<Response> _handleCreateApiKey(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return _errorResponse(400, 'API Key 名称不能为空');
      }

      // 解析过期选项
      final expiryStr = data['expiry'] as String? ?? 'never';
      final expiry = _parseExpiry(expiryStr);

      // 生成 API Key（不再需要加密密钥）
      final apiKey = await _authService.generateApiKey(
        userId: userId,
        name: name,
        expiry: expiry,
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'api_key': apiKey.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理列出 API Keys
  Future<Response> _handleListApiKeys(Request request) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      final keys = await _authService.listApiKeys(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'api_keys': keys.map((k) => k.toSafeJson()).toList(),
          'count': keys.length,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理撤销 API Key
  Future<Response> _handleRevokeApiKey(Request request, String keyId) async {
    try {
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      final success = await _authService.revokeApiKey(userId, keyId);

      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'API Key 已撤销' : '撤销失败',
          'key_id': keyId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 解析过期选项
  ApiKeyExpiry _parseExpiry(String value) {
    switch (value) {
      case '7days':
        return ApiKeyExpiry.sevenDays;
      case '30days':
        return ApiKeyExpiry.thirtyDays;
      case '90days':
        return ApiKeyExpiry.ninetyDays;
      case '1year':
        return ApiKeyExpiry.oneYear;
      case 'never':
      default:
        return ApiKeyExpiry.never;
    }
  }
}
