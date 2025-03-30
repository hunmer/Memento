import 'dart:convert';
import 'package:flutter/foundation.dart';

// 条件导入
import 'dart:io'
    if (dart.library.html) 'package:flutter_application_1/core/storage/web_file_stub.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/core/storage/web_storage.dart'
    if (dart.library.io) 'package:flutter_application_1/core/storage/native_storage_stub.dart'
    as storage;

// 不需要额外导入WebStorage，因为已经通过as storage导入了

/// 存储管理器，负责文件读写操作
class StorageManager {
  late String _basePath;
  final Map<String, dynamic> _cache = {};

  /// 创建存储管理器实例
  /// 注意：使用前需要调用 initialize() 方法确保初始化完成
  StorageManager();

  /// 初始化存储管理器
  Future<void> initialize() async {
    await _initBasePath();
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
        _basePath = '${directory.path}/app_data';

        // 确保基础目录存在
        final baseDir = Directory(_basePath);
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
    final dirPath = '$_basePath/$path';
    final directory = Directory(dirPath);

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
      // Web平台使用localStorage
      storage.saveData(path, content);
    } else {
      try {
        // 非Web平台使用文件系统
        final filePath = '$_basePath/$path';
        final file = File(filePath);

        // 确保目录存在
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        await file.writeAsString(content);
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
      // Web平台使用localStorage
      final content = storage.loadData(path);
      if (content != null) {
        _cache[path] = content;
        return content;
      }
      throw Exception('文件不存在: $path (Web平台)');
    }

    try {
      // 非Web平台读取文件
      final filePath = '$_basePath/$path';
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
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
    final jsonString = jsonEncode(data);
    await writeString(path, jsonString);
  }

  /// 读取JSON
  Future<dynamic> readJson(String path) async {
    final jsonString = await readString(path);
    return jsonDecode(jsonString);
  }

  /// 删除文件
  Future<void> deleteFile(String path) async {
    await _ensureInitialized();

    // 无论是否Web平台，都从缓存中移除
    _cache.remove(path);

    if (kIsWeb) {
      // Web平台从localStorage删除
      storage.removeData(path);
      return;
    }

    try {
      // 非Web平台删除文件
      final filePath = '$_basePath/$path';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
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

    // Web平台检查localStorage
    if (kIsWeb) {
      return storage.hasData(path);
    }

    try {
      // 非Web平台检查文件系统
      final filePath = '$_basePath/$path';
      final file = File(filePath);
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
      final directory = Directory(dirPath);
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
        // Web平台直接使用WebStorage的JSON方法
        final data = storage.loadJson(path);
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
    if (kIsWeb) {
      // Web平台直接使用WebStorage的JSON方法
      storage.saveJson(path, data);
      // 更新缓存
      _cache[path] = json.encode(data);
    } else {
      final jsonString = json.encode(data);
      await writeString(path, jsonString);
    }
  }

  /// 删除文件
  Future<void> delete(String path) async {
    await deleteFile(path);
  }

  /// 删除目录及其所有内容
  Future<void> deleteDirectory(String path) async {
    await _ensureInitialized();

    if (kIsWeb) {
      // Web平台需要删除所有以该路径开头的存储项
      storage.removeDataByPrefix(path);

      // 从缓存中删除所有相关项
      _cache.removeWhere((key, _) => key.startsWith(path));
    } else {
      try {
        // 非Web平台删除目录
        final dirPath = '$_basePath/$path';
        final directory = Directory(dirPath);

        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }

        // 从缓存中删除所有相关项
        _cache.removeWhere((key, _) => key.startsWith(path));
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
}
