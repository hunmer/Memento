import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/activity_timeline_screen.dart';

class ActivityPlugin extends PluginBase {
  static final ActivityPlugin instance = ActivityPlugin._internal();
  ActivityPlugin._internal();

  @override
  final String id = 'activity_plugin';

  @override
  final String name = 'Activity';

  @override
  final String version = '1.0.0';

  @override
  final String pluginDir = 'activity';

  @override
  String get description => '活动记录插件';

  @override
  String get author => 'Zhuanz';

  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'theme': 'light'},
    });
  }

  @override
  Future<void> initialize() async {
    // 确保活动记录数据目录存在
    await storage.createDirectory(pluginDir);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ActivityTimelineScreen();
  }
}
