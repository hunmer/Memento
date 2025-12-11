import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../services/auth_service.dart';
import '../services/plugin_data_service.dart';

/// 认证路由
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

    // POST /enable-api - 启用 API 访问 (需要认证)
    router.post('/enable-api', _handleEnableApi);

    // POST /disable-api - 禁用 API 访问 (需要认证)
    router.post('/disable-api', _handleDisableApi);

    // GET /api-status - 查询 API 启用状态 (需要认证)
    router.get('/api-status', _handleApiStatus);

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

  /// 处理启用 API 访问
  ///
  /// 请求体: { "encryption_key": "base64-encoded-key" }
  Future<Response> _handleEnableApi(Request request) async {
    try {
      // 验证 Token
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

      // 验证密钥格式 (应为 32 字节的 base64)
      try {
        await _pluginDataService!.enableApi(userId, encryptionKey);
      } catch (e) {
        return _errorResponse(400, '无效的加密密钥: $e');
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'API 访问已启用',
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理禁用 API 访问
  Future<Response> _handleDisableApi(Request request) async {
    try {
      // 验证 Token
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      await _pluginDataService!.disableApi(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'API 访问已禁用',
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理查询 API 状态
  Future<Response> _handleApiStatus(Request request) async {
    try {
      // 验证 Token
      final userId = _getUserIdFromRequest(request);
      if (userId == null) {
        return _errorResponse(401, '未认证或 Token 无效');
      }

      if (_pluginDataService == null) {
        return _errorResponse(503, 'API 服务未配置');
      }

      final isEnabled = _pluginDataService!.isApiEnabled(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'api_enabled': isEnabled,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }
}
