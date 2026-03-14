import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/plugin_data_service.dart';
import 'auth_middleware.dart';

/// API 启用检查中间件
///
/// 检查用户是否已启用 API 访问（设置了加密密钥）
/// 如果未启用，返回 403 Forbidden
///
/// 当使用 API Key 认证时，自动从 AuthContext 获取加密密钥
Middleware apiEnabledMiddleware(PluginDataService pluginDataService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 从请求上下文中获取认证信息（由 authMiddleware 设置）
      final authContext = getAuthContextFromRequest(request);
      final userId = request.context['userId'] as String?;

      if (userId == null) {
        return _errorResponse(401, '未认证');
      }

      // 如果使用 API Key 认证，检查是否有加密密钥
      if (authContext != null && authContext.isApiKey) {
        if (authContext.encryptionKey == null) {
          return _errorResponse(403, 'API Key 缺少加密密钥');
        }

        // 确保 API 访问已启用
        if (!pluginDataService.isApiEnabled(userId)) {
          // 自动启用 API 访问
          await pluginDataService.enableApi(userId, authContext.encryptionKey!);
        }

        // 将加密密钥添加到请求上下文
        final updatedRequest = request.change(
          context: {
            ...request.context,
            'encryptionKey': authContext.encryptionKey,
          },
        );
        return innerHandler(updatedRequest);
      }

      // JWT Token 认证：检查是否已启用 API
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
