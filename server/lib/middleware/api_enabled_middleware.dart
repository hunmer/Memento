import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/plugin_data_service.dart';

/// API 启用检查中间件
///
/// 检查用户是否已设置加密密钥
/// 加密密钥通过 X-Encryption-Key 请求头传递
Middleware apiEnabledMiddleware(PluginDataService pluginDataService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final userId = request.context['userId'] as String?;

      if (userId == null) {
        return _errorResponse(401, '未认证');
      }

      // 从请求头获取加密密钥
      final encryptionKey = request.headers['x-encryption-key'];

      if (encryptionKey == null || encryptionKey.isEmpty) {
        return _errorResponse(
          403,
          '请通过 X-Encryption-Key 请求头传递加密密钥',
        );
      }

      // 设置加密密钥到内存
      pluginDataService.setEncryptionKey(userId, encryptionKey);

      // 将加密密钥添加到请求上下文
      final updatedRequest = request.change(
        context: {
          ...request.context,
          'encryptionKey': encryptionKey,
        },
      );

      return innerHandler(updatedRequest);
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
