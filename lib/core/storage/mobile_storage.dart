import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

/// 移动平台的持久化存储实现
class MobileStorage implements StorageInterface {
  String _basePath = '';
  final Map<String, dynamic> _cache = {};

  /// 私有构造函数，防止实例化
  MobileStorage._() {
    _initBasePath();
  }

  /// 单例实例
  static final MobileStorage _instance = MobileStorage._();

  /// 获取单例实例
  static MobileStorage get instance => _instance;

  /// 初始化基础路径
  Future<void> _initBasePath() async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      _basePath = path.join(directory.path, 'app_data');

      // 确保基础目录存在
      final baseDir = io.Directory(_basePath);
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('初始化存储路径失败: $e');
      _basePath = 'fallback_storage';
    }
  }

  /// 确保基础路径已初始化
  Future<void> _ensureInitialized() async {
    if (_basePath.isEmpty) {
      await _initBasePath();
    }
  }

  /// 保存数据
  @override
  Future<void> saveData(String key, String value) async {
    await _ensureInitialized();
    _cache[key] = value;

    final fullPath = path.join(_basePath, key);
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
      await file.writeAsString(value);
    } catch (e) {
      debugPrint('写入文件失败: $fullPath - $e');
      throw Exception('写入文件失败: $fullPath - $e');
    }
  }

  /// 读取数据
  @override
  Future<String?> loadData(String key) async {
    await _ensureInitialized();

    // 先检查缓存
    if (_cache.containsKey(key)) {
      return _cache[key] as String;
    }

    try {
      final fullPath = path.join(_basePath, key);
      final file = io.File(fullPath);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      _cache[key] = content;
      return content;
    } catch (e) {
      debugPrint('读取文件失败: $key - $e');
      return null;
    }
  }

  /// 删除数据
  @override
  Future<void> removeData(String key) async {
    await _ensureInitialized();
    _cache.remove(key);

    try {
      final fullPath = path.join(_basePath, key);
      final file = io.File(fullPath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('删除文件失败: $key - $e');
    }
  }

  /// 检查数据是否存在
  @override
  Future<bool> hasData(String key) async {
    await _ensureInitialized();

    if (_cache.containsKey(key)) {
      return true;
    }

    try {
      final fullPath = path.join(_basePath, key);
      final file = io.File(fullPath);
      return await file.exists();
    } catch (e) {
      debugPrint('检查文件是否存在失败: $key - $e');
      return false;
    }
  }

  /// 保存JSON对象到SharedPreferences
  @override
  Future<void> saveJson(String key, dynamic data) async {
    debugPrint('saveJson: $key, $data');
    try {
      final jsonString = jsonEncode(data);
      await saveData(key, jsonString);
    } catch (e) {
      debugPrint('移动存储保存JSON失败: $key - $e');
    }
  }

  /// 从SharedPreferences读取JSON对象
  @override
  Future<dynamic> loadJson(String key) async {
    debugPrint('loadJson: $key');
    try {
      final jsonString = await loadData(key);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('移动存储读取JSON失败: $key - $e');
      return null;
    }
  }

  /// 获取所有以指定前缀开头的键
  @override
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    await _ensureInitialized();

    try {
      final fullPath = path.join(_basePath, prefix);
      final directory = io.Directory(fullPath);

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory.list(recursive: true).toList();
      return files
          .whereType<io.File>()
          .map((file) => path.relative(file.path, from: _basePath))
          .toList();
    } catch (e) {
      debugPrint('列出文件失败: $prefix - $e');
      return [];
    }
  }

  /// 清除所有以指定前缀开头的数据
  @override
  Future<void> clearWithPrefix(String prefix) async {
    try {
      final keys = await getKeysWithPrefix(prefix);
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('移动存储清除失败: $prefix - $e');
    }
  }

  /// 创建目录
  @override
  Future<void> createDirectory(String targetPath) async {
    await _ensureInitialized();
    final fullPath = path.join(_basePath, targetPath);
    final directory = io.Directory(fullPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// 读取字符串内容
  @override
  Future<String> readString(String targetPath) async {
    await _ensureInitialized();
    final fullPath = path.join(_basePath, targetPath);
    final file = io.File(fullPath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $targetPath');
    }
    return await file.readAsString();
  }

  /// 写入字符串内容
  @override
  Future<void> writeString(String targetPath, String content) async {
    await _ensureInitialized();
    final fullPath = path.join(_basePath, targetPath);
    final file = io.File(fullPath);

    // 确保目录存在
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await file.writeAsString(content);
  }

  /// 删除文件
  @override
  Future<void> deleteFile(String targetPath) async {
    await _ensureInitialized();
    final fullPath = path.join(_basePath, targetPath);
    final file = io.File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取应用文档目录
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    await _ensureInitialized();
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }
}
