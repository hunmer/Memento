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

  /// 插件图标
  IconData? get icon => Icons.extension;

  /// 插件颜色
  Color? get color => Colors.blue;

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

  /// 构建插件设置视图
  Widget buildSettingsView(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('数据存储位置'),
          subtitle: Text(storage.getPluginStoragePath(id)),
          trailing: const Icon(Icons.folder),
          onTap: () async {
            // TODO: 实现目录选择功能
          },
        ),
        const Divider(),
      ],
    );
  }

  /// 获取插件存储路径
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }
}
