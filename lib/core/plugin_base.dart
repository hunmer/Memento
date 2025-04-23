import 'package:flutter/material.dart';
import 'storage/storage_manager.dart';

/// 插件基类，所有插件必须继承此类
abstract class PluginBase {
  /// 插件唯一标识符
  String get id;

  /// 插件名称
  String get name;

  /// 插件版本
  String get version;

  /// 插件存储目录
  String get storageDir => getPluginStoragePath();

  /// 插件描述
  String get description;

  /// 插件作者
  String get author;

  /// 插件图标
  IconData? get icon => Icons.extension;

  /// 插件颜色
  Color? get color => Colors.blue;

  /// 存储管理器实例
  StorageManager? _storage;
  
  /// 获取存储管理器
  StorageManager get storage {
    if (_storage == null) {
      throw StateError('Storage manager has not been initialized');
    }
    return _storage!;
  }

  /// 插件配置
  Map<String, dynamic> _settings = {};

  /// 获取插件配置
  Map<String, dynamic> get settings => _settings;

  /// 设置存储管理器
  void setStorageManager(StorageManager storageManager) {
    _storage = storageManager;
  }

  /// 加载插件配置
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read('$storageDir/settings.json');
      if (storedSettings.isNotEmpty) {
        _settings = Map<String, dynamic>.from(storedSettings);
        // 确保所有默认配置项都存在
        bool needsUpdate = false;
        for (var entry in defaultSettings.entries) {
          if (!_settings.containsKey(entry.key)) {
            _settings[entry.key] = entry.value;
            needsUpdate = true;
          }
        }
        if (needsUpdate) {
          await saveSettings();
        }
      } else {
        _settings = Map<String, dynamic>.from(defaultSettings);
        await saveSettings();
      }
    } catch (e) {
      _settings = Map<String, dynamic>.from(defaultSettings);
      try {
        await saveSettings();
      } catch (e) {
        print('Warning: Failed to save plugin settings: $e');
      }
    }
  }

  /// 保存插件配置
  Future<void> saveSettings() async {
    try {
      await storage.write('$storageDir/settings.json', _settings);
    } catch (e) {
      print('Warning: Failed to save plugin settings: $e');
    }
  }

  /// 更新插件配置
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await saveSettings();
  }

  /// 初始化插件
  Future<void> initialize();

  /// 构建插件主视图
  Widget buildMainView(BuildContext context);

  /// 构建插件卡片视图
  /// 如果插件需要自定义卡片显示样式，可以重写此方法
  Widget? buildCardView(BuildContext context) => null;

  /// 构建插件设置视图
  Widget buildSettingsView(BuildContext context) {
    return Column(
      children: [
      
      ],
    );
  }

  /// 获取插件存储路径
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }
}
