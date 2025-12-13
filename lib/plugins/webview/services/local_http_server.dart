import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

/// 本地 HTTP 服务器
/// 用于在 Windows 等平台上提供本地文件访问，绕过 file:// 协议的安全限制
class LocalHttpServer {
  HttpServer? _server;
  int _port = 8080;
  String _rootDir = '';
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get port => _port;
  String get serverUrl => 'http://localhost:$_port';

  /// 启动服务器
  ///
  /// [rootDir] 服务器根目录路径
  /// [port] 服务器端口（默认 8080）
  Future<bool> start({required String rootDir, int port = 8080}) async {
    if (_isRunning) {
      debugPrint('[LocalHttpServer] 服务器已在运行');
      return true;
    }

    try {
      _rootDir = rootDir;
      _port = port;

      // 尝试绑定端口，如果失败则尝试下一个端口
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts) {
        try {
          _server = await HttpServer.bind('127.0.0.1', _port);
          break;
        } catch (e) {
          debugPrint('[LocalHttpServer] 端口 $_port 被占用，尝试下一个端口');
          _port++;
          attempts++;
        }
      }

      if (_server == null) {
        debugPrint('[LocalHttpServer] 无法启动服务器：所有端口都被占用');
        return false;
      }

      debugPrint('[LocalHttpServer] 服务器启动成功: $serverUrl');
      debugPrint('[LocalHttpServer] 根目录: $_rootDir');

      // 监听请求
      _server!.listen(_handleRequest);
      _isRunning = true;

      return true;
    } catch (e) {
      debugPrint('[LocalHttpServer] 启动服务器失败: $e');
      return false;
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _isRunning = false;
      debugPrint('[LocalHttpServer] 服务器已停止');
    }
  }

  /// 处理 HTTP 请求
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      var path = Uri.decodeComponent(request.uri.path);

      // 默认文件
      if (path == '/') {
        path = '/index.html';
      }

      // 构建文件路径
      var filePath = _rootDir + path.replaceAll('/', Platform.pathSeparator);
      var file = File(filePath);

      debugPrint('[LocalHttpServer] 请求文件: $filePath');

      // 如果文件不存在，尝试从 Referer 中提取项目名称
      if (!await file.exists()) {
        final referer = request.headers.value('referer');
        if (referer != null) {
          // 从 Referer 中提取项目名称
          // 例如：http://localhost:8080/projectName/index.html -> projectName
          final projectName = _extractProjectNameFromReferer(referer);
          if (projectName != null) {
            // 尝试在项目目录下查找文件
            final projectFilePath = _rootDir +
                Platform.pathSeparator +
                projectName +
                path.replaceAll('/', Platform.pathSeparator);
            final projectFile = File(projectFilePath);

            debugPrint('[LocalHttpServer] 尝试项目路径: $projectFilePath');

            if (await projectFile.exists()) {
              file = projectFile;
              filePath = projectFilePath;
            }
          }
        }
      }

      if (await file.exists()) {
        // 获取 MIME 类型
        var mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

        // 设置响应头
        request.response.headers.contentType = ContentType.parse(mimeType);

        // 添加 CORS 头（允许跨域请求）
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        // 添加缓存控制头（开发环境不缓存）
        request.response.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
        request.response.headers.add('Pragma', 'no-cache');
        request.response.headers.add('Expires', '0');

        // 发送文件内容
        await request.response.addStream(file.openRead());

        debugPrint('[LocalHttpServer] 成功返回文件: $filePath (MIME: $mimeType)');
      } else {
        // 文件不存在
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('File not found: $path');

        debugPrint('[LocalHttpServer] 文件不存在: $filePath');
      }
    } catch (e) {
      // 处理错误
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal server error: $e');

      debugPrint('[LocalHttpServer] 处理请求错误: $e');
    } finally {
      await request.response.close();
    }
  }

  /// 从 Referer 中提取项目名称
  ///
  /// 例如：http://localhost:8080/projectName/index.html -> projectName
  String? _extractProjectNameFromReferer(String referer) {
    try {
      final uri = Uri.parse(referer);
      final pathSegments = uri.pathSegments;

      // 如果有路径段，第一个段就是项目名称
      if (pathSegments.isNotEmpty) {
        return pathSegments.first;
      }
    } catch (e) {
      debugPrint('[LocalHttpServer] 解析 Referer 失败: $e');
    }
    return null;
  }

  /// 将 file:// URL 转换为 HTTP URL
  ///
  /// 例如：
  /// - file:///D:/path/to/file.html -> http://localhost:8080/path/to/file.html
  /// - file:///path/to/file.html -> http://localhost:8080/path/to/file.html
  String convertFileUrlToHttpUrl(String fileUrl) {
    if (!fileUrl.startsWith('file://')) {
      return fileUrl;
    }

    // 移除 file:// 前缀
    String path = fileUrl.substring('file://'.length);

    // Windows 路径处理：移除开头的 /
    if (Platform.isWindows && path.startsWith('/')) {
      path = path.substring(1);
    }

    // 移除根目录前缀
    if (path.startsWith(_rootDir)) {
      path = path.substring(_rootDir.length);
    }

    // 标准化路径分隔符为 /
    path = path.replaceAll(Platform.pathSeparator, '/');

    // 确保路径以 / 开头
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return '$serverUrl$path';
  }

  /// 检查 URL 是否为可转换的本地文件 URL
  bool isConvertibleFileUrl(String url) {
    if (!url.startsWith('file://')) {
      return false;
    }

    // 提取文件路径
    String path = url.substring('file://'.length);

    // Windows 路径处理
    if (Platform.isWindows && path.startsWith('/')) {
      path = path.substring(1);
    }

    // 检查是否在根目录下
    return path.startsWith(_rootDir);
  }

  /// 将任意文件路径转换为 HTTP URL
  ///
  /// [filePath] 文件绝对路径
  String filePathToHttpUrl(String filePath) {
    // 标准化路径
    String normalizedPath = filePath.replaceAll(Platform.pathSeparator, '/');

    // 移除根目录前缀
    if (normalizedPath.startsWith(_rootDir.replaceAll(Platform.pathSeparator, '/'))) {
      normalizedPath = normalizedPath.substring(_rootDir.length);
    }

    // 确保路径以 / 开头
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    return '$serverUrl$normalizedPath';
  }
}
