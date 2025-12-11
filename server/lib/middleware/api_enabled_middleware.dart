import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/plugin_data_service.dart';

/// API 启用检查中间件
///
/// 检查用户是否已启用 API 访问（设置了加密密钥）
/// 如果未启用，返回 403 Forbidden
Middleware apiEnabledMiddleware(PluginDataService pluginDataService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 从请求上下文中获取 userId（由 authMiddleware 设置）
      final userId = request.context['userId'] as String?;

      if (userId == null) {
        return _errorResponse(401, '未认证');
      }

      if (!pluginDataService.isApiEnabled(userId)) {
        return _errorResponse(
          403,
          'API 访问未启用，请先调用 /api/v1/auth/enable-api',
        );
      }

      return innerHandler(request);
    };
  };
}

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
