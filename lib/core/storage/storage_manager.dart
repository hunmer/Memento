import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

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
      final directory = await getApplicationDocumentsDirectory();
      _basePath = '${directory.path}/app_data';

      // 确保基础目录存在
      final baseDir = Directory(_basePath);
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('初始化存储路径失败: $e');
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
    final filePath = '$_basePath/$path';
    final file = File(filePath);

    // 确保目录存在
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await file.writeAsString(content);
    _cache[path] = content;
  }

  /// 读取字符串
  Future<String> readString(String path) async {
    await _ensureInitialized();

    if (_cache.containsKey(path)) {
      return _cache[path] as String;
    }

    final filePath = '$_basePath/$path';
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('文件不存在', filePath);
    }

    final content = await file.readAsString();
    _cache[path] = content;
    return content;
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
    final filePath = '$_basePath/$path';
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      _cache.remove(path);
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String path) async {
    await _ensureInitialized();
    final filePath = '$_basePath/$path';
    final file = File(filePath);
    return file.exists();
  }

  /// 确保目录存在
  Future<void> ensureDirectoryExists(String path) async {
    await _ensureInitialized();
    final dirPath = '$_basePath/$path';
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// 读取 JSON 文件
  Future<Map<String, dynamic>> read(String path) async {
    try {
      final content = await readString(path);
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('读取 JSON 文件失败: $e');
      return {};
    }
  }

  /// 写入 JSON 文件
  Future<void> write(String path, Map<String, dynamic> data) async {
    final jsonString = json.encode(data);
    await writeString(path, jsonString);
  }

  /// 删除文件
  Future<void> delete(String path) async {
    await deleteFile(path);
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
