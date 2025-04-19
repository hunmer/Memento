import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:webdav_client/webdav_client.dart';

import 'storage_interface.dart';
import 'mobile_storage.dart';

// 条件导入，只在Web平台编译时才会导入
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage.dart'
    as web_storage;

/// 存储管理器，负责文件读写操作
class StorageManager {
  late String _basePath;
  final Map<String, dynamic> _cache = {};
  late StorageInterface _storage;

  // WebDAV相关
  Client? _webdavClient;
  String? _webdavBasePath;
  bool _useWebDAV = false;

  /// 创建存储管理器实例
  /// 注意：使用前需要调用 initialize() 方法确保初始化完成
  StorageManager() {
    // 根据平台选择合适的存储实现
    if (kIsWeb) {
      // 在非Web平台编译时，这里会使用stub实现
      // 在Web平台编译时，会使用实际的WebStorage实现
      _storage = web_storage.WebStorage.instance;
    } else {
      _storage = MobileStorage.instance;
    }
  }

  /// 初始化存储管理器
  Future<void> initialize() async {
    await _initBasePath();
    await _initWebDAV();
  }

  /// 初始化WebDAV连接
  Future<void> _initWebDAV() async {
    try {
      // 检查是否存在WebDAV配置
      if (await fileExists('webdav_config.json')) {
        final config = await readJson('webdav_config.json');
        if (config['isConnected'] == true) {
          // 配置WebDAV客户端
          _webdavClient = newClient(
            config['url'],
            user: config['username'],
            password: config['password'],
            debug: true,
          );

          _webdavBasePath = config['dataPath'];
          _useWebDAV = true;

          // 测试连接
          try {
            await _webdavClient!.ping();
            debugPrint('WebDAV连接成功');
          } catch (e) {
            debugPrint('WebDAV连接失败: $e');
            _useWebDAV = false;
          }
        }
      }
    } catch (e) {
      debugPrint('初始化WebDAV失败: $e');
      _useWebDAV = false;
    }
  }

  /// 配置WebDAV
  Future<void> configureWebDAV({
    required String url,
    required String username,
    required String password,
    required String dataPath,
    required bool enabled,
  }) async {
    if (enabled) {
      _webdavClient = newClient(
        url,
        user: username,
        password: password,
        debug: true,
      );

      _webdavBasePath = dataPath;
      _useWebDAV = true;

      // 保存配置
      await writeJson('webdav_config.json', {
        'url': url,
        'username': username,
        'password': password,
        'dataPath': dataPath,
        'isConnected': true,
      });

      // 确保远程目录存在
      try {
        await _webdavClient!.mkdir(dataPath);
      } catch (e) {
        // 目录可能已存在，忽略错误
      }
    } else {
      _useWebDAV = false;
      _webdavClient = null;
      _webdavBasePath = null;

      // 保存配置
      await writeJson('webdav_config.json', {'isConnected': false});
    }
  }

  /// 检查WebDAV是否已配置
  bool get isWebDAVConfigured => _useWebDAV && _webdavClient != null;

  /// 获取基础路径
  String get basePath => _basePath;

  /// 初始化基础路径
  Future<void> _initBasePath() async {
    try {
      if (kIsWeb) {
        // Web平台使用固定路径
        _basePath = 'web_app_data';
        debugPrint('Web平台使用内存存储: $_basePath');
      } else {
        // 非Web平台使用文件系统
        final directory = await getApplicationDocumentsDirectory();
        _basePath = '${directory.path}/app_data';

        // 确保基础目录存在
        final baseDir = io.Directory(_basePath);
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('初始化存储路径失败: $e');
      // 出错时使用备用路径
      _basePath = 'fallback_storage';
    }
  }

  /// 确保基础路径已初始化
  Future<void> _ensureInitialized() async {
    if (_basePath.isEmpty) {
      await _initBasePath();
    }
  }

  /// 创建目录
  Future<void> createDirectory(String path) async {
    await _ensureInitialized();

    // Web平台不支持目录创建，直接返回
    if (kIsWeb) {
      debugPrint('Web平台跳过目录创建: $path');
      return;
    }

    final dirPath = '$_basePath/$path';
    final directory = io.Directory(dirPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// 写入字符串
  Future<void> writeString(String path, String content) async {
    await _ensureInitialized();

    // 更新内存缓存
    _cache[path] = content;

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.saveData(path, content);
    } else {
      try {
        // 非Web平台使用文件系统
        final filePath = '$_basePath/$path';
        final file = io.File(filePath);

        // 确保目录存在
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        await file.writeAsString(content);

        // 如果WebDAV已配置，同时写入WebDAV
        if (_useWebDAV && _webdavClient != null && _webdavBasePath != null) {
          try {
            final webdavPath = '$_webdavBasePath/$path';

            // 确保WebDAV目录存在
            final dirPath = webdavPath.substring(
              0,
              webdavPath.lastIndexOf('/'),
            );
            try {
              await _webdavClient!.mkdir(dirPath);
            } catch (e) {
              // 目录可能已存在，忽略错误
            }

            // 写入WebDAV文件
            await _webdavClient!.write(
              webdavPath,
              Uint8List.fromList(content.codeUnits),
            );
        }
      } catch (e) {
        debugPrint('写入文件失败: $path - $e');
        // 失败时只保留在缓存中
      }
    }
  }

  /// 读取字符串
  Future<String> readString(String path) async {
    await _ensureInitialized();

    // 先检查缓存
    if (_cache.containsKey(path)) {
      return _cache[path] as String;
    }

    if (kIsWeb) {
      // Web平台使用抽象接口
      final content = await _storage.loadData(path);
      if (content != null) {
        _cache[path] = content;
        return content;
      }
      throw Exception('文件不存在: $path (Web平台)');
    }

    try {
      // 如果WebDAV已配置且优先使用，尝试从WebDAV读取
      if (_useWebDAV && _webdavClient != null && _webdavBasePath != null) {
        try {
          final webdavPath = '$_webdavBasePath/$path';
          final bytes = await _webdavClient!.read(webdavPath);
          final content = utf8.decode(bytes);
          _cache[path] = content;
          return content;
        } catch (e) {
          debugPrint('从WebDAV读取失败，尝试本地读取: $path - $e');
          // 如果WebDAV读取失败，继续尝试本地读取
        }
      }

      // 非Web平台读取文件
      final filePath = '$_basePath/$path';
      final file = io.File(filePath);

      if (!await file.exists()) {
        throw io.FileSystemException('文件不存在', filePath);
      }

      final content = await file.readAsString();
      _cache[path] = content;
      return content;
    } catch (e) {
      debugPrint('读取文件失败: $path - $e');
      throw Exception('读取文件失败: $path - $e');
    }
  }

  /// 写入JSON
  Future<void> writeJson(String path, dynamic data) async {
    if (kIsWeb) {
      await _storage.saveJson(path, data);
      // 更新缓存
      _cache[path] = jsonEncode(data);
    } else {
      final jsonString = jsonEncode(data);
      await writeString(path, jsonString);
    }
  }

  /// 读取JSON
  Future<dynamic> readJson(String path) async {
    if (kIsWeb) {
      return await _storage.loadJson(path);
    } else {
      final jsonString = await readString(path);
      return jsonDecode(jsonString);
    }
  }

  /// 删除文件
  Future<void> deleteFile(String path) async {
    await _ensureInitialized();

    // 无论是否Web平台，都从缓存中移除
    _cache.remove(path);

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.removeData(path);
      return;
    }

    try {
      // 非Web平台删除文件
      final filePath = '$_basePath/$path';
      final file = io.File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      // 如果WebDAV已配置，同时删除WebDAV中的文件
      if (_useWebDAV && _webdavClient != null && _webdavBasePath != null) {
        try {
          final webdavPath = '$_webdavBasePath/$path';
          await _webdavClient!.remove(webdavPath);
        } catch (e) {
          debugPrint('WebDAV删除文件失败: $path - $e');
        }
      }
    } catch (e) {
      debugPrint('删除文件失败: $path - $e');
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String path) async {
    await _ensureInitialized();

    // 先检查缓存
    if (_cache.containsKey(path)) {
      return true;
    }

    // 使用抽象接口
    if (kIsWeb) {
      return await _storage.hasData(path);
    }

    try {
      // 非Web平台检查文件系统
      final filePath = '$_basePath/$path';
      final file = io.File(filePath);
      return file.exists();
    } catch (e) {
      debugPrint('检查文件是否存在失败: $path - $e');
      return false;
    }
  }

  /// 确保目录存在
  Future<void> ensureDirectoryExists(String path) async {
    await _ensureInitialized();

    // Web平台不需要创建目录
    if (kIsWeb) {
      return;
    }

    try {
      // 非Web平台创建目录
      final dirPath = '$_basePath/$path';
      final directory = io.Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('创建目录失败: $path - $e');
    }
  }

  /// 读取 JSON 文件
  Future<Map<String, dynamic>> read(String path) async {
    try {
      if (kIsWeb) {
        // Web平台使用抽象接口
        final data = await _storage.loadJson(path);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
        return {};
      } else {
        final content = await readString(path);
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('读取 JSON 文件失败: $e');
      return {};
    }
  }

  /// 写入 JSON 文件
  Future<void> write(String path, Map<String, dynamic> data) async {
    await writeJson(path, data);
  }

  /// 删除文件
  Future<void> delete(String path) async {
    await deleteFile(path);
  }

  /// 删除目录及其所有内容
  Future<void> deleteDirectory(String path) async {
    await _ensureInitialized();

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.clearWithPrefix(path);

      // 从缓存中删除所有相关项
      _cache.removeWhere((key, _) => key.startsWith(path));
    } else {
      try {
        // 非Web平台删除目录
        final dirPath = '$_basePath/$path';
        final directory = io.Directory(dirPath);

        if (await directory.exists()) {
          // 递归删除目录及其内容
          await for (var entity in directory.list(recursive: true)) {
            await entity.delete();
          }
          await directory.delete();
        }

        // 从缓存中删除所有相关项
        _cache.removeWhere((key, _) => key.startsWith(path));

        // 如果WebDAV已配置，同时删除WebDAV中的目录
        if (_useWebDAV && _webdavClient != null && _webdavBasePath != null) {
          try {
            final webdavPath = '$_webdavBasePath/$path';
            await _webdavClient!.remove(webdavPath);
          } catch (e) {
            debugPrint('WebDAV删除目录失败: $path - $e');
          }
        }
      } catch (e) {
        debugPrint('删除目录失败: $path - $e');
      }
    }
  }

  /// 初始化文件（如果不存在则写入默认值）
  Future<void> initializeWithDefault(
    String path,
    Map<String, dynamic> defaultData,
  ) async {
    if (!await fileExists(path)) {
      await write(path, defaultData);
    }
  }

  /// 读取文件内容为字符串（别名方法，与 readString 功能相同）
  Future<String> readFile(String path) async {
    return await readString(path);
  }

  /// 写入字符串到文件（别名方法，与 writeString 功能相同）
  Future<void> writeFile(String path, String content) async {
    await writeString(path, content);
  }

  /// 获取插件存储路径
  String getPluginStoragePath(String pluginId) {
    // 返回插件的完整存储路径
    if (kIsWeb) {
      return 'web_app_data/$pluginId';
    } else {
      return '$_basePath/$pluginId';
    }
  }

  /// 确保插件目录存在
  Future<void> ensurePluginDirectoryExists(String pluginId) async {
    final pluginPath = getPluginStoragePath(pluginId);
    await ensureDirectoryExists(pluginPath);
  }

  /// 读取插件文件
  Future<String> readPluginFile(String pluginId, String fileName) async {
    final pluginPath = getPluginStoragePath(pluginId);
    return await readString('$pluginPath/$fileName');
  }

  /// 写入插件文件
  Future<void> writePluginFile(
    String pluginId,
    String fileName,
    String content,
  ) async {
    final pluginPath = getPluginStoragePath(pluginId);
    await writeString('$pluginPath/$fileName', content);
  }

  /// 清除内存缓存
  void clearMemoryCache() {
    _cache.clear();
  }
}
