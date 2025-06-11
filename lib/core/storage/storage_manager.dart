import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:path/path.dart' as path;

import 'storage_interface.dart';
import 'mobile_storage.dart';

// 条件导入，只在Web平台编译时才会导入
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage.dart'
    as web_storage;

/// 存储管理器，负责文件读写操作
class StorageManager {
  String _basePath = '';
  final Map<String, dynamic> _cache = {};
  late StorageInterface _storage;

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
  }

  /// 保存WebDAV配置信息（仅保存配置，不直接连接）
  Future<void> saveWebDAVConfig({
    required String url,
    required String username,
    required String password,
    required String dataPath,
    required bool enabled,
    bool? autoSync,
  }) async {
    // 读取现有配置以保留未明确设置的值
    Map<String, dynamic> config = {};
    if (await fileExists('webdav_config.json')) {
      try {
        config = await readJson('webdav_config.json') as Map<String, dynamic>;
      } catch (e) {
        debugPrint('读取现有WebDAV配置失败: $e');
      }
    }

    // 更新配置
    config['url'] = url;
    config['username'] = username;
    config['password'] = password;
    config['dataPath'] = dataPath;
    config['isConnected'] = enabled;
    config['enabled'] = enabled;

    // 只有在明确设置时才更新autoSync
    if (autoSync != null) {
      config['autoSync'] = autoSync;
    }

    // 保存配置到本地
    await writeJson('webdav_config.json', config);
  }

  /// 获取WebDAV配置
  Future<Map<String, dynamic>?> getWebDAVConfig() async {
    try {
      if (await fileExists('webdav_config.json')) {
        return await readJson('webdav_config.json') as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('获取WebDAV配置失败: $e');
      return null;
    }
  }

  /// 设置字符串值（与 writeString 功能相同，但使用更直观的命名）
  Future<void> setString(String key, String value) async {
    await writeString(key, value);
  }

  /// 获取字符串值（与 readString 功能相同，但使用更直观的命名）
  Future<String> getString(String key) async {
    return await readString(key);
  }

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
        // 使用path.join确保路径分隔符在不同平台上兼容
        _basePath = path.join(directory.path, 'app_data');

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
  Future<void> createDirectory(String dirPath) async {
    await _ensureInitialized();

    // Web平台不支持目录创建，直接返回
    if (kIsWeb) {
      debugPrint('Web平台跳过目录创建: $dirPath');
      return;
    }

    final fullPath = path.join(_basePath, dirPath);
    final directory = io.Directory(fullPath);

    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
        debugPrint('创建目录成功: $fullPath');
      } catch (e) {
        debugPrint('创建目录失败: $fullPath - $e');
        throw Exception('创建目录失败: $fullPath - $e');
      }
    }
  }

  /// 写入字符串
  Future<void> writeString(String filePath, String content) async {
    await _ensureInitialized();

    // 更新内存缓存
    _cache[filePath] = content;

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.saveData(filePath, content);
    } else {
      // 非Web平台使用文件系统
      final fullPath = path.join(_basePath, filePath);
      final file = io.File(fullPath);

      // 确保目录存在
      final directory = file.parent;
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          debugPrint('创建目录失败: ${directory.path} - $e');
          throw Exception('创建目录失败: ${directory.path} - $e');
        }
      }

      try {
        await file.writeAsString(content);
      } catch (e) {
        debugPrint('写入文件失败: $fullPath - $e');
        throw Exception('写入文件失败: $fullPath - $e');
      }
    }
  }

  /// 读取字符串
  Future<String> readString(String filePath) async {
    await _ensureInitialized();

    // 先检查缓存
    if (_cache.containsKey(filePath)) {
      return _cache[filePath] as String;
    }

    if (kIsWeb) {
      // Web平台使用抽象接口
      final content = await _storage.loadData(filePath);
      if (content != null) {
        _cache[filePath] = content;
        return content;
      }
      throw Exception('文件不存在: $filePath (Web平台)');
    }

    // 从本地文件系统读取
    try {
      // 非Web平台读取文件
      final fullPath = path.join(_basePath, filePath);
      final file = io.File(fullPath);

      if (!await file.exists()) {
        throw io.FileSystemException('文件不存在', fullPath);
      }

      final content = await file.readAsString();
      _cache[filePath] = content;
      return content;
    } catch (e) {
      throw Exception('读取文件失败: $filePath - $e');
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

      // 这里可以添加JSON文件变化监控代码，用于后续同步到WebDAV
    }
  }

  /// 读取JSON
  /// [path] 文件路径
  /// [defaultValue] 当文件不存在时返回的默认值
  Future<dynamic> readJson(String path, [dynamic defaultValue]) async {
    try {
      if (kIsWeb) {
        final result = await _storage.loadJson(path);
        return result ?? defaultValue;
      } else {
        final jsonString = await readString(path);
        return jsonDecode(jsonString);
      }
    } catch (e) {
      return defaultValue;
    }
  }

  /// 删除文件
  Future<void> deleteFile(String filePath) async {
    await _ensureInitialized();

    // 无论是否Web平台，都从缓存中移除
    _cache.remove(filePath);

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.removeData(filePath);
      return;
    }

    try {
      // 非Web平台删除文件
      final fullPath = path.join(_basePath, filePath);
      final file = io.File(fullPath);

      if (await file.exists()) {
        await file.delete();
      }

      // 这里可以添加文件删除事件监控代码，用于后续同步到WebDAV
    } catch (e) {
      // debugPrint('删除文件失败: $fullPath - $e');
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    await _ensureInitialized();

    // 先检查缓存
    if (_cache.containsKey(filePath)) {
      return true;
    }

    // 使用抽象接口
    if (kIsWeb) {
      return await _storage.hasData(filePath);
    }

    try {
      // 非Web平台检查文件系统
      final fullPath = path.join(_basePath, filePath);
      final file = io.File(fullPath);
      return file.exists();
    } catch (e) {
      // debugPrint('检查文件是否存在失败: $fullPath - $e');
      return false;
    }
  }

  /// 确保目录存在
  Future<void> ensureDirectoryExists(String dirPath) async {
    await _ensureInitialized();

    // Web平台不需要创建目录
    if (kIsWeb) {
      return;
    }

    try {
      // 非Web平台创建目录
      final fullPath = path.join(_basePath, dirPath);
      final directory = io.Directory(fullPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        debugPrint('创建目录成功: $fullPath');
      }
    } catch (e) {
      debugPrint('创建目录失败: $dirPath - $e');
      throw Exception('创建目录失败: $dirPath - $e');
    }
  }

  /// 读取 JSON 文件
  ///
  /// [path] 文件路径
  /// [defaultValue] 当文件不存在或读取失败时返回的默认值，如果不指定则返回空对象 {}
  Future<Map<String, dynamic>> read(
    String path, [
    Map<String, dynamic>? defaultValue,
  ]) async {
    try {
      if (kIsWeb) {
        // Web平台使用抽象接口
        final data = await _storage.loadJson(path);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
        return defaultValue ?? {};
      } else {
        final content = await readString(path);
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      return defaultValue ?? {};
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
  Future<void> deleteDirectory(String dirPath) async {
    await _ensureInitialized();

    if (kIsWeb) {
      // Web平台使用抽象接口
      await _storage.clearWithPrefix(dirPath);

      // 从缓存中删除所有相关项
      _cache.removeWhere((key, _) => key.startsWith(dirPath));
    } else {
      try {
        // 非Web平台删除目录
        final fullPath = path.join(_basePath, dirPath);
        final directory = io.Directory(fullPath);

        if (await directory.exists()) {
          // 递归删除目录及其内容
          await for (var entity in directory.list(recursive: true)) {
            await entity.delete();
          }
          await directory.delete();
        }

        // 从缓存中删除所有相关项
        // 确保路径分隔符处理正确，使用标准化的路径格式进行比较
        final normalizedDirPath = path.normalize(dirPath);
        _cache.removeWhere((key, _) {
          final normalizedKey = path.normalize(key);
          return normalizedKey.startsWith(normalizedDirPath);
        });

        // 这里可以添加目录删除事件监控代码，用于后续同步到WebDAV
      } catch (e) {
        // debugPrint('删除目录失败: $fullPath - $e');
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

  /// 读取文件内容为字符串
  ///
  /// [path] 文件路径
  /// [defaultValue] 当文件不存在或读取失败时返回的默认值
  ///
  /// 如果提供了默认值，则在文件不存在或读取失败时返回默认值，而不会抛出异常
  Future<String> readFile(String path, [String? defaultValue]) async {
    try {
      return await readString(path);
    } catch (e) {
      if (defaultValue != null) {
        return defaultValue;
      }
      // 如果没有提供默认值，则继续抛出异常
      rethrow;
    }
  }

  /// 写入字符串到文件（别名方法，与 writeString 功能相同）
  Future<void> writeFile(String path, String content) async {
    await writeString(path, content);
  }

  /// 获取插件存储路径
  String getPluginStoragePath(String pluginId) {
    // 返回插件的完整存储路径，确保路径分隔符在不同平台上兼容
    if (kIsWeb) {
      return path.join('web_app_data', pluginId);
    } else {
      return path.join(_basePath, pluginId);
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
    // 使用path.join确保路径分隔符在不同平台上兼容
    return await readString(path.join(pluginPath, fileName));
  }

  /// 写入插件文件
  Future<void> writePluginFile(
    String pluginId,
    String fileName,
    String content,
  ) async {
    final pluginPath = getPluginStoragePath(pluginId);
    // 使用path.join确保路径分隔符在不同平台上兼容
    await writeString(path.join(pluginPath, fileName), content);
  }

  /// 清除内存缓存
  void clearMemoryCache() {
    _cache.clear();
  }

  /// 列出指定目录下的所有文件
  Future<List<String>> listFiles(String dirPath) async {
    await _ensureInitialized();

    if (kIsWeb) {
      // Web平台使用抽象接口
      return await _storage.getKeysWithPrefix(dirPath);
    }

    // 非Web平台使用文件系统
    try {
      final fullPath = path.join(_basePath, dirPath);
      final directory = io.Directory(fullPath);

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory.list(recursive: false).toList();
      return files
          .whereType<io.File>()
          .map((file) => path.relative(file.path, from: _basePath))
          .toList();
    } catch (e) {
      debugPrint('列出文件失败: $dirPath - $e');
      return [];
    }
  }
}
