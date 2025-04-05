import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';
import '../core/config_manager.dart';
import '../core/storage/storage_manager.dart';
import '../core/plugin_base.dart';

/// 插件基类，所有插件都应该继承这个类
abstract class BasePlugin extends PluginBase {
  late StorageManager _storageManager;

  /// 设置存储管理器
  @override
  void setStorageManager(StorageManager storageManager) {
    _storageManager = storageManager;
  }

  /// 获取存储管理器
  StorageManager get storageManager => _storageManager;
  @override
  StorageManager get storage => _storageManager;

  /// 插件ID
  @override
  String get id;

  /// 插件名称
  @override
  String get name;

  /// 插件版本
  @override
  String get version;

  /// 插件描述
  @override
  String get description;

  /// 插件作者
  @override
  String get author;

  /// 插件存储目录
  @override
  String get storageDir => getPluginStoragePath();

  /// 向应用注册插件
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  );

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
