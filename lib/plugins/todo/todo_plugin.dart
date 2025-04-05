import 'package:flutter/material.dart';
import '../base_plugin.dart';
import 'screens/todo_main_screen.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';

class TodoPlugin extends BasePlugin {
  // 单例实例
  static final TodoPlugin instance = TodoPlugin._internal();

  // 私有构造函数
  TodoPlugin._internal();

  @override
  String get id => 'todo_plugin';

  @override
  String get name => 'Todo';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'A plugin for managing tasks and to-do lists';

  @override
  String get author => 'Your Name';

  @override
  IconData get icon => Icons.check_circle_outline;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 在这里注册插件到应用程序
    // 例如：注册设置、配置默认值等
  }

  @override
  Future<void> initialize() async {
    // 在这里初始化插件
    // 例如：加载数据、设置初始状态等
    await initializeDefaultData();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TodoMainScreen();
  }

  @override
  Future<void> initializeDefaultData() async {
    // 在这里初始化默认数据
    // 例如：创建默认任务、分组等
  }
}
