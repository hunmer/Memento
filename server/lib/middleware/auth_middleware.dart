import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/auth_service.dart';

/// JWT 认证中间件
///
/// 验证请求头中的 Authorization Bearer Token
/// 成功后将 userId 添加到 request.context
Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 跳过 OPTIONS 请求 (CORS 预检)
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      // 获取 Authorization 头
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return _unauthorizedResponse('缺少或格式错误的 Authorization 头');
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
