import 'dart:io'
    show Platform, HttpServer, HttpRequest, File, HttpStatus, ContentType;
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

// 导入用于自动配置的类型
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/webview/webview_plugin.dart';
import 'package:Memento/core/storage/storage_manager.dart';

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
        // 获取 MIME 类型（优先使用自定义映射）
        var mimeType = _getMimeType(filePath);

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

  /// 从 Referer 中提取项目路径
  ///
  /// 例如：http://localhost:8080/webview/http_server/dist/index.html -> webview/http_server/dist
  /// 例如：http://localhost:8080/projectName/index.html -> projectName
  String? _extractProjectNameFromReferer(String referer) {
    try {
      final uri = Uri.parse(referer);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        return null;
      }

      // 移除最后一个段（文件名），保留目录路径
      // 例如：[webview, http_server, dist, index.html] -> webview/http_server/dist
      final dirPath = pathSegments
          .sublist(0, pathSegments.length - 1)
          .join('/');

      return dirPath.isNotEmpty ? dirPath : null;
    } catch (e) {
      debugPrint('[LocalHttpServer] 解析 Referer 失败: $e');
    }
    return null;
  }

  /// 获取文件的 MIME 类型
  ///
  /// 优先使用自定义映射，确保常见文件类型返回正确的 MIME 类型
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    // 自定义 MIME 类型映射（确保常见文件类型正确识别）
    const mimeMap = {
      '.html': 'text/html',
      '.htm': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.mjs': 'application/javascript',
      '.json': 'application/json',
      '.xml': 'application/xml',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
      '.webp': 'image/webp',
      '.woff': 'font/woff',
      '.woff2': 'font/woff2',
      '.ttf': 'font/ttf',
      '.otf': 'font/otf',
      '.eot': 'application/vnd.ms-fontobject',
      '.mp4': 'video/mp4',
      '.webm': 'video/webm',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.ogg': 'audio/ogg',
      '.pdf': 'application/pdf',
      '.zip': 'application/zip',
      '.txt': 'text/plain',
      '.md': 'text/markdown',
    };

    // 优先使用自定义映射
    if (mimeMap.containsKey(extension)) {
      return mimeMap[extension]!;
    }

    // 回退到 mime 包的 lookupMimeType
    final mimeType = lookupMimeType(filePath);
    if (mimeType != null) {
      return mimeType;
    }

    // 默认返回二进制流类型
    return 'application/octet-stream';
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
    if (UniversalPlatform.isWindows && path.startsWith('/')) {
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
    if (UniversalPlatform.isWindows && path.startsWith('/')) {
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

  /// 获取 HTTP 服务器的完整 URL 前缀（静态方法）
  ///
  /// [port] 服务器端口（默认 8080）
  /// [appDataRoot] app_data 根目录路径
  /// [filePath] 要转换的文件路径
  ///
  /// 返回 HTTP URL，例如：http://localhost:8080/webview/http_server/project/index.html
  static String getHttpUrl({
    required int port,
    required String appDataRoot,
    required String filePath,
  }) {
    final serverUrl = 'http://localhost:$port';
    String normalizedPath = filePath.replaceAll(Platform.pathSeparator, '/');

    // 移除 app_data 根目录前缀
    final normalizedRoot = appDataRoot.replaceAll(Platform.pathSeparator, '/');
    if (normalizedPath.startsWith(normalizedRoot)) {
      normalizedPath = normalizedPath.substring(normalizedRoot.length);
    }

    // 确保路径以 / 开头
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    return '$serverUrl$normalizedPath';
  }

  // ==================== 静态方法（供其他插件复用） ====================

  /// 获取 HTTP 服务器的完整 URL 前缀（静态方法）
  ///
  /// 此方法供其他插件复用，将本地图片路径转换为可通过 HTTP 访问的 URL。
  ///
  /// 参数：
  /// - [imagePath] 图片路径（支持相对路径 ./xxx.png、file:// URL、绝对路径、网络 URL）
  /// - [httpServerRoot] HTTP 服务器根目录（现在是 app_data 目录）
  /// - [port] HTTP 服务器端口（默认 8080）
  /// - [pluginStoragePath] 插件存储路径（可选，用于解析相对路径）
  ///
  /// 返回：
  /// - 网络图片 URL 直接返回
  /// - 本地图片路径返回 http://localhost:port/xxx 格式的 URL
  /// - 转换失败返回原始路径
  ///
  /// 示例：
  /// ```dart
  /// final httpUrl = await LocalHttpServer.convertImageToHttpUrl(
  ///   imagePath: './app_images/icon.png',
  ///   httpServerRoot: '/path/to/app_data',
  ///   port: 8080,
  ///   pluginStoragePath: '/path/to/app_data/store',
  /// );
  /// // 返回: 'http://localhost:8080/app_images/icon.png'
  /// ```
  static Future<String> convertImageToHttpUrl({
    required String? imagePath,
    required String httpServerRoot,
    int port = 8080,
    String? pluginStoragePath,
  }) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // 如果已经是网络 URL，直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    try {
      String filePathToConvert;

      if (imagePath.startsWith('./')) {
        // 相对路径：./app_images/xxx.png
        final relativePath = imagePath.substring(2); // 移除 ./
        // 直接使用 HTTP 服务器根目录（app_data），不检查文件是否存在
        filePathToConvert = '$httpServerRoot/${relativePath.replaceAll('/', Platform.pathSeparator)}';
      } else if (imagePath.startsWith('file://')) {
        // file:// URL，提取路径部分
        filePathToConvert = imagePath.substring('file://'.length);
        if (UniversalPlatform.isWindows && filePathToConvert.startsWith('/')) {
          filePathToConvert = filePathToConvert.substring(1);
        }
      } else {
        // 其他情况，假设是相对于插件目录的路径
        if (pluginStoragePath != null && pluginStoragePath.isNotEmpty) {
          filePathToConvert = '$pluginStoragePath/${imagePath.replaceAll('/', Platform.pathSeparator)}';
        } else {
          // 没有插件存储路径，直接使用相对于根目录的路径
          filePathToConvert = '$httpServerRoot/${imagePath.replaceAll('/', Platform.pathSeparator)}';
        }
      }

      // 转换为 HTTP URL
      return getHttpUrl(port: port, appDataRoot: httpServerRoot, filePath: filePathToConvert);
    } catch (e) {
      debugPrint('[LocalHttpServer] 图片路径转换失败: $e');
      return imagePath;
    }
  }

  /// 批量转换图片路径（静态方法）
  ///
  /// 参数：
  /// - [items] 包含图片字段的数据列表
  /// - [imageKey] 图片字段的键名（默认 'image'）
  /// - [httpServerRoot] HTTP 服务器根目录
  /// - [port] HTTP 服务器端口（默认 8080）
  /// - [pluginStoragePath] 插件存储路径（可选）
  ///
  /// 返回：处理后的数据列表（不修改原始数据）
  static Future<List<Map<String, dynamic>>> convertImagesInItems({
    required List<dynamic> items,
    String imageKey = 'image',
    required String httpServerRoot,
    int port = 8080,
    String? pluginStoragePath,
  }) async {
    final processedItems = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final updatedItem = Map<String, dynamic>.from(item);
        final imagePath = updatedItem[imageKey] as String?;
        if (imagePath != null && imagePath.isNotEmpty) {
          updatedItem[imageKey] = await convertImageToHttpUrl(
            imagePath: imagePath,
            httpServerRoot: httpServerRoot,
            port: port,
            pluginStoragePath: pluginStoragePath,
          );
        }
        processedItems.add(updatedItem);
      }
    }

    return processedItems;
  }

  /// 批量转换图片路径（自动配置版本）
  ///
  /// 这是一个便捷方法，自动获取 WebView 插件和 HTTP 服务器配置。
  /// 适用于其他插件在 JS API 中快速转换图片路径。
  ///
  /// 参数：
  /// - [items] 包含图片字段的数据列表
  /// - [pluginId] 当前插件的 ID
  /// - [imageKey] 图片字段的键名（默认 'image'）
  /// - [storageManager] StorageManager 实例（可选）
  ///
  /// 返回：处理后的数据列表
  ///
  /// 使用示例：
  /// ```dart
  /// // 在插件 JS API 中
  /// var products = await useCase.getProducts(params);
  /// if (getHttpImage) {
  ///   products = await LocalHttpServer.convertImagesWithAutoConfig(
  ///     items: products,
  ///     pluginId: id,
  ///     imageKey: 'image',
  ///     storageManager: storageManager,
  ///   );
  /// }
  /// ```
  static Future<List<Map<String, dynamic>>> convertImagesWithAutoConfig({
    required List<dynamic> items,
    required String pluginId,
    String imageKey = 'image',
    StorageManager? storageManager,
  }) async {
    if (items.isEmpty) {
      return [];
    }

    try {
      // 获取 WebView 插件
      final webViewPlugin = PluginManager.instance.getPlugin('webview') as WebViewPlugin?;

      if (webViewPlugin == null) {
        debugPrint('[LocalHttpServer] ⚠️ WebView 插件未初始化，跳过图片转换');
        return items.cast<Map<String, dynamic>>().toList();
      }

      if (!webViewPlugin.localHttpServer.isRunning) {
        debugPrint('[LocalHttpServer] ⚠️ HTTP 服务器未运行，跳过图片转换');
        return items.cast<Map<String, dynamic>>().toList();
      }

      // 获取配置
      final httpServerRoot = await webViewPlugin.getHttpServerRootDir();
      final port = webViewPlugin.localHttpServer.port;
      String? pluginStoragePath;

      // 获取插件存储路径（如果提供了 StorageManager）
      if (storageManager != null) {
        pluginStoragePath = storageManager.getPluginStoragePath(pluginId);
      }

      debugPrint('[LocalHttpServer] 开始转换图片 [plugin: $pluginId, count: ${items.length}]');

      // 使用静态方法批量转换图片
      final result = await convertImagesInItems(
        items: items,
        imageKey: imageKey,
        httpServerRoot: httpServerRoot,
        port: port,
        pluginStoragePath: pluginStoragePath,
      );

      debugPrint('[LocalHttpServer] ✓ 图片转换完成 [plugin: $pluginId]');
      return result;
    } catch (e) {
      debugPrint('[LocalHttpServer] ✗ 图片转换失败 [plugin: $pluginId]: $e');
      return items.cast<Map<String, dynamic>>().toList();
    }
  }

  /// 转换单个数据项中的图片路径（静态方法）
  ///
  /// 参数：
  /// - [item] 包含图片字段的数据
  /// - [imageKey] 图片字段的键名（默认 'image'）
  /// - [httpServerRoot] HTTP 服务器根目录
  /// - [port] HTTP 服务器端口（默认 8080）
  /// - [pluginStoragePath] 插件存储路径（可选）
  ///
  /// 返回：处理后的数据（不修改原始数据），如果输入为 null 则返回 null
  static Future<Map<String, dynamic>?> convertImageInItem({
    required Map<String, dynamic>? item,
    String imageKey = 'image',
    required String httpServerRoot,
    int port = 8080,
    String? pluginStoragePath,
  }) async {
    if (item == null) return null;

    final updatedItem = Map<String, dynamic>.from(item);
    final imagePath = updatedItem[imageKey] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      updatedItem[imageKey] = await convertImageToHttpUrl(
        imagePath: imagePath,
        httpServerRoot: httpServerRoot,
        port: port,
        pluginStoragePath: pluginStoragePath,
      );
    }
    return updatedItem;
  }
}
