import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../plugin_widget.dart';
import 'screens/todo_main_screen.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'services/todo_service.dart';

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
    // 初始化TodoService，传入storageManager
    final todoService = TodoService.getInstance(storage);
    await todoService.init();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return PluginWidget(plugin: this, child: const TodoMainScreen());
  }
}
