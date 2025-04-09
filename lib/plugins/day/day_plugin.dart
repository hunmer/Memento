import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'screens/day_home_screen.dart';

class DayPlugin extends BasePlugin {
  static final DayPlugin instance = DayPlugin._internal();
  DayPlugin._internal();

  @override
  final String id = 'day_plugin';

  @override
  final String name = 'Day';

  @override
  final String version = '1.0.0';

  @override
  final String pluginDir = 'day';

  @override
  String get description => '纪念日管理插件';

  @override
  String get author => 'Zhuanz';

  @override
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
      'settings': {'defaultView': 'card'},
    });
  }

  @override
  Future<void> initialize() async {
    // 确保纪念日数据目录存在
    await storage.createDirectory(pluginDir);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const DayHomeScreen();
  }
}