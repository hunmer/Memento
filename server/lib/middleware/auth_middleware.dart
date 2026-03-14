import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/auth_service.dart';

/// 认证上下文数据
class AuthContext {
  final String userId;
  final String? encryptionKey;
  final String? keyId;
  final String? keyName;
  final bool isApiKey;

  AuthContext({
    required this.userId,
    this.encryptionKey,
    this.keyId,
    this.keyName,
    this.isApiKey = false,
  });
}

/// JWT 认证中间件
///
/// 支持两种认证方式：
/// 1. Authorization: Bearer <jwt_token>
/// 2. X-API-Key: <api_key>
///
/// 成功后将认证信息添加到 request.context
Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 跳过 OPTIONS 请求 (CORS 预检)
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      // 优先检查 X-API-Key 头
      final apiKeyHeader = request.headers['x-api-key'];
      if (apiKeyHeader != null && apiKeyHeader.isNotEmpty) {
        final result = await authService.verifyApiKey(apiKeyHeader);
        if (result == null) {
          return _unauthorizedResponse('API Key 无效或已过期');
        }

        final updatedRequest = request.change(
          context: {
            ...request.context,
            'userId': result.userId,
            'authContext': AuthContext(
              userId: result.userId,
              encryptionKey: result.encryptionKey,
              keyId: result.keyId,
              keyName: result.keyName,
              isApiKey: true,
            ),
          },
        );
        return innerHandler(updatedRequest);
      }

      // 检查 Authorization Bearer Token
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return _unauthorizedResponse('缺少认证信息');
      }

      // 提取 Token
      final token = authHeader.substring(7); // 去掉 "Bearer " 前缀

      // 验证 Token
      final userId = authService.getUserIdFromToken(token);

      if (userId == null) {
        return _unauthorizedResponse('Token 无效或已过期');
      }

      // 将 userId 添加到请求上下文
      final updatedRequest = request.change(
        context: {
          ...request.context,
          'userId': userId,
          'authContext': AuthContext(
            userId: userId,
            isApiKey: false,
          ),
        },
      );

      return innerHandler(updatedRequest);
    };
  };
}

/// 生成 401 未授权响应
Response _unauthorizedResponse(String message) {
  return Response(
    401,
    body: jsonEncode({
      'success': false,
      'error': message,
      'timestamp': DateTime.now().toIso8601String(),
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

/// 从请求上下文获取用户 ID 的辅助函数
String? getUserIdFromContext(Request request) {
  return request.context['userId'] as String?;
}

/// 从请求上下文获取认证上下文的辅助函数
AuthContext? getAuthContextFromRequest(Request request) {
  return request.context['authContext'] as AuthContext?;
}
