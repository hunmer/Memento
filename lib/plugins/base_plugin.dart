import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';
import '../core/config_manager.dart';
import '../core/storage/storage_manager.dart';
import '../core/plugin_base.dart';

/// 插件基类，所有插件都应该继承这个类
abstract class BasePlugin extends PluginBase {
  StorageManager? _storageManager;

  /// 设置存储管理器
  @override
  void setStorageManager(StorageManager storageManager) {
    _storageManager = storageManager;
  }

  /// 获取存储管理器
  StorageManager get storageManager {
    if (_storageManager == null) {
      // 尝试从 PluginManager 获取 StorageManager
      final pluginManager = PluginManager.instance;
      if (pluginManager.storageManager != null) {
        _storageManager = pluginManager.storageManager;
      } else {
        throw StateError('StorageManager has not been initialized');
      }
    }
    return _storageManager!;
  }

  @override
  StorageManager get storage => storageManager;

  /// 插件ID
  @override
  String get id;

  /// 插件存储目录
  @override
  String get storageDir => getPluginStoragePath();

  /// 向应用注册插件
  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 子类需要实现此方法
  }

  /// 初始化插件
  @override
  Future<void> initialize();

  /// 初始化默认数据
  Future<void> initializeDefaultData() async {}

  /// 构建主视图
  @override
  Widget buildMainView(BuildContext context);

  /// 卸载插件
  Future<void> uninstall() async {}
}
