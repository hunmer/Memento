import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/diary_calendar_screen.dart';

class DiaryPlugin extends BasePlugin {
  static final DiaryPlugin instance = DiaryPlugin._internal();
  DiaryPlugin._internal();

  @override
  final String id = 'diary_plugin';

  @override
  final String name = 'Diary';

  @override
  final String version = '1.0.0';

  @override
  final String pluginDir = 'diary';

  @override
  String get description => '日记管理插件';

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
    // 确保日记数据目录存在
    await storage.createDirectory(pluginDir);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DiaryCalendarScreen(storage: storage);
  }
}
