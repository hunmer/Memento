import 'package:flutter/material.dart';
import 'storage/storage_manager.dart';
import 'plugin_manager.dart';
import 'config_manager.dart';

/// 插件数据刷新参数
class PluginRefreshDataArgs {
  /// 触发刷新的文件路径
  final String filePath;

  /// 触发源（websocket, manual, etc）
  final String source;

  /// 时间戳
  final DateTime timestamp;

  PluginRefreshDataArgs({
    required this.filePath,
    this.source = 'sync',
  }) : timestamp = DateTime.now();
}

/// 插件基类，所有插件必须继承此类
abstract class PluginBase {
  /// 插件唯一标识符
  String get id;

  /// 插件存储目录
  String get storageDir => getPluginStoragePath();

  /// 插件图标
  IconData? get icon => Icons.extension;

  /// 插件颜色
  Color? get color => Colors.blue;

  /// 存储管理器实例
  StorageManager? _storage;

  /// 获取存储管理器
  /// 如果未设置存储管理器会抛出详细异常
  StorageManager get storage {
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

  String getPluginSettingPath() => ConfigManager.getPluginConfigPath(id);

  /// 加载插件配置
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read(getPluginSettingPath());
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
      await storage.write(getPluginSettingPath(), _settings);
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

  /// 注册到应用程序
  /// 用于在插件初始化后进行额外的设置，如注册服务、设置监听器等
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {}

  /// 构建插件主视图
  Widget buildMainView(BuildContext context);

  /// 构建插件卡片视图
  /// 如果插件需要自定义卡片显示样式，可以重写此方法
  Widget? buildCardView(BuildContext context) => null;

  /// 构建插件设置视图
  Widget buildSettingsView(BuildContext context) {
    return Column(children: [
      
      ],
    );
  }

  /// 获取插件存储路径
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }

  String? getPluginName(context) {
    return null;
  }

  /// 刷新插件数据（可选实现）
  ///
  /// 当数据通过同步服务更新时调用，插件应重写此方法以重新加载内存中的数据。
  /// 默认实现返回 false 表示未实现刷新功能。
  ///
  /// 参数:
  /// - [args] 刷新参数，包含触发源和文件路径
  ///
  /// 返回值:
  /// - true: 刷新成功
  /// - false: 未实现刷新或刷新失败
  Future<bool> refreshData([PluginRefreshDataArgs? args]) async {
    return false;
  }

  /// 是否支持指定文件的刷新（可选实现）
  ///
  /// 子类可重写以实现更精细的文件级别刷新控制
  bool supportsFileRefresh(String filePath) => true;
}
