import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage/storage_manager.dart';

/// 配置管理器，负责管理插件配置
class ConfigManager {
  final StorageManager _storage;
  final Map<String, dynamic> _configs = {};

  ConfigManager(this._storage);

  /// 初始化配置管理器
  Future<void> initialize() async {
    // Web平台不需要创建目录，只需要确保存储管理器已初始化
    if (!kIsWeb) {
      await _storage.createDirectory('configs');
    }
  }

  /// 保存插件配置
  Future<void> savePluginConfig(
    String pluginId,
    Map<String, dynamic> config,
  ) async {
    _configs[pluginId] = config;
    await _storage.writeString('configs/$pluginId.json', jsonEncode(config));
  }

  /// 获取插件配置
  Future<Map<String, dynamic>?> getPluginConfig(String pluginId) async {
    if (_configs.containsKey(pluginId)) {
      return _configs[pluginId];
    }

    try {
      final configStr = await _storage.readString('configs/$pluginId.json');
      final config = jsonDecode(configStr) as Map<String, dynamic>;
      _configs[pluginId] = config;
      return config;
    } catch (e) {
      return null;
    }
  }

  /// 删除插件配置
  Future<void> deletePluginConfig(String pluginId) async {
    _configs.remove(pluginId);
    await _storage.deleteFile('configs/$pluginId.json');
  }
}
