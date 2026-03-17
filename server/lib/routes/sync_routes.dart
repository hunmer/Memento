import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../services/file_storage_service.dart';
import '../services/plugin_data_service.dart';
import '../services/websocket_manager.dart';
import '../middleware/auth_middleware.dart';

/// 同步路由 - 处理文件推送、拉取和列表
class SyncRoutes {
  final FileStorageService _storageService;
  final WebSocketManager? _webSocketManager;
  final PluginDataService? _pluginDataService;

  SyncRoutes(this._storageService, [this._webSocketManager, this._pluginDataService]);

  Router get router {
    final router = Router();

    // POST /push - 推送加密文件
    router.post('/push', _handlePush);

    // GET /pull/<filePath> - 拉取加密文件
    // 使用通配符匹配任意路径
    router.get('/pull/<filePath|.*>', _handlePull);

    // GET /pull-decrypted/<filePath> - 拉取解密后的文件 (用于管理后台)
    router.get('/pull-decrypted/<filePath|.*>', _handlePullDecrypted);

    // GET /info/<filePath> - 获取文件元信息（不含内容）
    router.get('/info/<filePath|.*>', _handleInfo);

    // GET /ws - WebSocket 连接（需要特殊处理）
    // 注意: WebSocket 端点需要在主服务器中单独处理

    // GET /list - 列出用户所有文件
    router.get('/list', _handleList);

    // DELETE /delete/<filePath> - 删除文件
    router.delete('/delete/<filePath|.*>', _handleDelete);

    // GET /status - 同步状态
    router.get('/status', _handleStatus);

    // GET /tree - 获取目录树结构
    router.get('/tree', _handleTree);

    // POST /export - 导出ZIP文件
    router.post('/export', _handleExport);

    // GET /download/<fileName> - 下载导出文件
    router.get('/download/<fileName|.*>', _handleDownload);

    return router;
  }

  /// 处理文件推送
  Future<Response> _handlePush(Request request) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 验证必填字段
      final filePath = data['file_path'] as String?;
      final encryptedData = data['encrypted_data'] as String?;
      final newMd5 = data['new_md5'] as String?;

      if (filePath == null || encryptedData == null || newMd5 == null) {
        return _errorResponse(400, '缺少必填字段: file_path, encrypted_data, new_md5');
      }

      // 验证文件路径安全性 (防止路径遍历攻击)
      if (filePath.contains('..') || filePath.startsWith('/')) {
        return _errorResponse(400, '无效的文件路径');
      }

      final oldMd5 = data['old_md5'] as String?;
      final isBinary = data['is_binary'] as bool? ?? false;

      // 读取服务器当前文件 (如果存在)
      final serverFile =
          await _storageService.readEncryptedFile(userId, filePath);

      // 如果文件存在且提供了 oldMd5，进行冲突检测
      if (serverFile != null && oldMd5 != null) {
        final currentMd5 = serverFile['md5'] as String;

        if (currentMd5 != oldMd5) {
          // 冲突: 返回 409 + 服务器数据
          // 客户端将根据策略处理 (服务器优先: 自动使用服务器版本)
          final response = SyncResponse.conflict(
            filePath: filePath,
            serverData: serverFile['encrypted_data'] as String,
            serverMd5: currentMd5,
            serverUpdatedAt: DateTime.parse(serverFile['updated_at'] as String),
            isBinary: serverFile['is_binary'] as bool? ?? false,
          );

          // 记录冲突日志
          await _storageService.logSync(
            userId: userId,
            action: 'conflict',
            filePath: filePath,
            details: 'old_md5: $oldMd5, server_md5: $currentMd5',
          );

          return Response(
            409,
            body: response.toJsonString(),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      // 保存文件
      await _storageService.writeEncryptedFile(
        userId,
        filePath,
        encryptedData,
        newMd5,
        isBinary: isBinary,
      );

      // 记录成功日志
      await _storageService.logSync(
        userId: userId,
        action: 'push',
        filePath: filePath,
        details: 'md5: $newMd5',
      );

      // 广播文件更新通知给其他设备
      final deviceId = getDeviceIdFromContext(request);
      if (_webSocketManager != null && deviceId != null) {
        _webSocketManager!.broadcastFileUpdate(
          userId,
          filePath,
          newMd5,
          DateTime.now(),
          deviceId,
        );
      }

      final response = SyncResponse.success(
        filePath: filePath,
        newMd5: newMd5,
      );

      return Response.ok(
        response.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理文件拉取
  Future<Response> _handlePull(Request request, String filePath) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      // 验证文件路径安全性
      if (filePath.contains('..') || filePath.startsWith('/')) {
        return _errorResponse(400, '无效的文件路径');
      }

      final serverFile =
          await _storageService.readEncryptedFile(userId, filePath);

      if (serverFile == null) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'error': '文件不存在',
            'file_path': filePath,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 记录拉取日志
      await _storageService.logSync(
        userId: userId,
        action: 'pull',
        filePath: filePath,
      );

      final response = PullResponse(
        encryptedData: serverFile['encrypted_data'] as String,
        md5: serverFile['md5'] as String,
        updatedAt: DateTime.parse(serverFile['updated_at'] as String),
        isBinary: serverFile['is_binary'] as bool? ?? false,
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理文件拉取（解密后）- 用于管理后台
  ///
  /// 需要通过 X-Encryption-Key 请求头传递加密密钥
  Future<Response> _handlePullDecrypted(Request request, String filePath) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      // 验证文件路径安全性
      if (filePath.contains('..') || filePath.startsWith('/')) {
        return _errorResponse(400, '无效的文件路径');
      }

      // 检查是否启用了解密服务
      if (_pluginDataService == null) {
        return _errorResponse(503, '解密服务未配置');
      }

      // 从请求头获取加密密钥
      final encryptionKey = request.headers['x-encryption-key'];
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return _errorResponse(403, '请通过 X-Encryption-Key 请求头传递加密密钥');
      }

      // 设置加密密钥（仅内存）
      _pluginDataService!.setEncryptionKey(userId, encryptionKey);

      final serverFile =
          await _storageService.readEncryptedFile(userId, filePath);

      if (serverFile == null) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'error': '文件不存在',
            'file_path': filePath,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final encryptedData = serverFile['encrypted_data'] as String?;
      if (encryptedData == null) {
        return _errorResponse(500, '文件数据为空');
      }

      // 解密数据
      final decryptedData = _pluginDataService!.encryptionService.decryptData(
        userId,
        encryptedData,
      );

      // 记录拉取日志
      await _storageService.logSync(
        userId: userId,
        action: 'pull_decrypted',
        filePath: filePath,
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'file_path': filePath,
          'data': decryptedData,
          'md5': serverFile['md5'],
          'updated_at': serverFile['updated_at'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '解密失败: $e');
    }
  }

  /// 处理文件信息查询（不含内容）
  Future<Response> _handleInfo(Request request, String filePath) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      // 验证文件路径安全性
      if (filePath.contains('..') || filePath.startsWith('/')) {
        return _errorResponse(400, '无效的文件路径');
      }

      final serverFile =
          await _storageService.readEncryptedFile(userId, filePath);

      if (serverFile == null) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'exists': false,
            'file_path': filePath,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // 获取文件大小
      final userDir = _storageService.getUserDir(userId);
      final file = File('$userDir/$filePath');
      final fileSize = await file.exists() ? await file.length() : 0;

      return Response.ok(
        jsonEncode({
          'success': true,
          'exists': true,
          'file_path': filePath,
          'md5': serverFile['md5'] as String,
          'modified_at': serverFile['updated_at'] as String,
          'size': fileSize,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理文件列表
  Future<Response> _handleList(Request request) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      final files = await _storageService.listUserFiles(userId);

      final response = FileListResponse(
        files: files,
        timestamp: DateTime.now(),
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理文件删除
  Future<Response> _handleDelete(Request request, String filePath) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      // 验证文件路径安全性
      if (filePath.contains('..') || filePath.startsWith('/')) {
        return _errorResponse(400, '无效的文件路径');
      }

      final deleted = await _storageService.deleteFile(userId, filePath);

      if (deleted) {
        // 记录删除日志
        await _storageService.logSync(
          userId: userId,
          action: 'delete',
          filePath: filePath,
        );

        return Response.ok(
          jsonEncode({
            'success': true,
            'file_path': filePath,
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'error': '文件不存在',
            'file_path': filePath,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理同步状态
  Future<Response> _handleStatus(Request request) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      final files = await _storageService.listUserFiles(userId);
      final totalSize = await _storageService.getUserDataSize(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'user_id': userId,
          'file_count': files.length,
          'total_size_bytes': totalSize,
          'total_size_mb': (totalSize / 1024 / 1024).toStringAsFixed(2),
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
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

  /// 处理目录树结构
  Future<Response> _handleTree(Request request) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      final tree = await _storageService.getDirectoryTree(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'tree': tree.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '服务器错误: $e');
    }
  }

  /// 处理ZIP导出
  Future<Response> _handleExport(Request request) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      final result = await _storageService.exportUserDataAsZip(userId);

      // 记录导出日志
      await _storageService.logSync(
        userId: userId,
        action: 'export',
        filePath: result['file_name'] as String,
        details: 'file_count: ${result['metadata']['file_count']}, total_size: ${result['metadata']['total_size']}',
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(500, '导出失败: $e');
    }
  }

  /// 处理下载导出文件
  Future<Response> _handleDownload(Request request, String fileName) async {
    final userId = getUserIdFromContext(request);
    if (userId == null) {
      return _errorResponse(401, '未授权');
    }

    try {
      // 验证文件名安全性
      if (fileName.contains('..') || fileName.contains('/')) {
        return _errorResponse(400, '无效的文件名');
      }

      final exportDir = _storageService.getExportDir();
      final filePath = path.join(exportDir, fileName);

      final file = File(filePath);
      if (!await file.exists()) {
        return _errorResponse(404, '文件不存在');
      }

      // 记录下载日志
      await _storageService.logSync(
        userId: userId,
        action: 'download',
        filePath: fileName,
      );

      return Response(
        200,
        body: file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition': 'attachment; filename="$fileName"',
          'Content-Length': (await file.length()).toString(),
        },
      );
    } catch (e) {
      return _errorResponse(500, '下载失败: $e');
    }
  }
}
