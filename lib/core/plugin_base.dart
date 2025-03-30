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

  /// 插件目录名
  String get pluginDir;

  /// 插件描述
  String get description;

  /// 插件作者
  String get author;

  /// 存储管理器实例
  late final StorageManager storage;

  /// 设置存储管理器
  void setStorageManager(StorageManager storageManager) {
    storage = storageManager;
  }

  /// 初始化插件
  Future<void> initialize();

  /// 构建插件主视图
  Widget buildMainView(BuildContext context);
}
