import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'storage_interface.dart';
import 'mobile_storage.dart';
import 'web_storage.dart' as web_storage;

/// 轻量级存储管理器
class StorageManager {
  final _cache = <String, dynamic>{};
  late final StorageInterface _storage =
      kIsWeb ? web_storage.WebStorage.instance : MobileStorage.instance;

  /// 保存WebDAV配置
  Future<void> saveWebDAVConfig({
    required String url,
    required String username,
    required String password,
    required String dataPath,
    required bool enabled,
    bool? autoSync,
  }) async {
    final config = {
      'url': url,
      'username': username,
      'password': password,
      'dataPath': dataPath,
      'enabled': enabled,
      if (autoSync != null) 'autoSync': autoSync,
    };
    await _storage.saveJson('webdav_config.json', config);
  }

  /// 获取WebDAV配置
  Future<Map<String, dynamic>?> getWebDAVConfig() async {
    return await _storage.loadJson('webdav_config.json');
  }

  /// 保存数据
  Future<void> save(String key, dynamic value) async {
    if (value is String) {
      await _saveString(key, value);
    } else {
      await _saveJson(key, value);
    }
  }

  /// 读取数据
  Future<dynamic> load(String key, [dynamic defaultValue]) async {
    return await _readJson(key, defaultValue);
  }

  /// 删除数据
  Future<void> remove(String key) async {
    _cache.remove(key);
    await _storage.removeData(key);
  }

  /// 检查数据是否存在
  Future<bool> exists(String key) async {
    return _cache.containsKey(key) || await _storage.hasData(key);
  }

  /// 清除指定前缀的数据
  Future<void> clearPrefix(String prefix) async {
    await _storage.clearWithPrefix(prefix);
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// 获取插件存储路径
  String getPluginPath(String pluginId) => 'plugins/$pluginId';

  /// 插件数据操作
  Future<void> savePluginData(String pluginId, String key, dynamic value) =>
      save('${getPluginPath(pluginId)}/$key', value);

  Future<dynamic> loadPluginData(
    String pluginId,
    String key, [
    dynamic defaultValue,
  ]) => load('${getPluginPath(pluginId)}/$key', defaultValue);

  /// 清除内存缓存
  void clearCache() => _cache.clear();

  /// 初始化存储管理器
  Future<void> initialize() async {}

  /// 读取数据 (别名方法)
  Future<dynamic> read(String key, [dynamic defaultValue]) =>
      readJson(key, defaultValue);

  /// 写入数据 (别名方法)
  Future<void> write(String key, dynamic value) => save(key, value);

  /// 读取文件内容
  Future<String> readFile(String path, [String defaultValue = '']) async {
    try {
      return await readString(path);
    } catch (e) {
      return defaultValue;
    }
  }

  /// 写入文件内容
  Future<void> writeFile(String path, String content) =>
      writeString(path, content);

  /// 获取插件存储路径 (公开方法)
  String getPluginStoragePath(String id) => getPluginPath(id);

  /// 获取应用文档目录
  /// 如果是浏览器环境返回'memento_app'，其他环境返回正常的应用文档目录
  static Future<Directory> getApplicationDocumentsDirectory() async {
    if (kIsWeb) {
      // 在web环境中创建虚拟目录对象
      return Directory('memento_app');
    }
    return await path_provider.getApplicationDocumentsDirectory();
  }

  /// 创建目录
  Future<void> createDirectory(String path) async {
    await _storage.createDirectory(path);
  }

  /// 读取字符串内容
  Future<String> readString(String path) async {
    return await _storage.readString(path);
  }

  /// 写入字符串内容
  Future<void> writeString(String path, String content) async {
    await _storage.writeString(path, content);
  }

  /// 删除文件
  Future<void> deleteFile(String path) async {
    await _storage.deleteFile(path);
  }

  /// 写入JSON数据
  Future<void> writeJson(String path, dynamic data) async {
    await _storage.saveJson(path, data);
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String path) async {
    return await exists(path);
  }

  /// 删除数据 (别名方法)
  Future<void> delete(String key) async {
    await remove(key);
  }

  /// 获取字符串数据
  Future<String?> getString(String key) async {
    try {
      return await readString(key);
    } catch (e) {
      return null;
    }
  }

  /// 设置字符串数据
  Future<void> setString(String key, String value) async {
    await writeString(key, value);
  }

  /// 读取JSON数据
  Future<dynamic> readJson(String path, [dynamic defaultValue]) async {
    return await _storage.loadJson(path, defaultValue);
  }

  /// 确保插件目录存在
  Future<void> ensurePluginDirectoryExists(String pluginId) async {
    await createDirectory(getPluginPath(pluginId));
  }

  /// 读取插件文件
  Future<String> readPluginFile(String pluginId, String fileName) async {
    final path = '${getPluginPath(pluginId)}/$fileName';
    return await readString(path);
  }

  /// 写入插件文件
  Future<void> writePluginFile(
    String pluginId,
    String fileName,
    String content,
  ) async {
    final path = '${getPluginPath(pluginId)}/$fileName';
    await writeString(path, content);
  }

  // 私有方法
  Future<void> _saveString(String key, String value) async {
    _cache[key] = value;
    await _storage.saveData(key, value);
  }

  Future<String> _readString(String key) async {
    if (_cache.containsKey(key)) return _cache[key] as String;
    final content = await _storage.loadData(key);
    if (content == null) throw Exception('数据不存在: $key');
    _cache[key] = content;
    return content;
  }

  Future<void> _saveJson(String key, dynamic data) async {
    final jsonStr = jsonEncode(data);
    await _saveString(key, jsonStr);
  }

  Future<dynamic> _readJson(String key, [dynamic defaultValue]) async {
    try {
      final jsonStr = await _readString(key);
      return jsonDecode(jsonStr);
    } catch (e) {
      return defaultValue;
    }
  }
}
