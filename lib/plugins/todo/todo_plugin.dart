import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'controllers/controllers.dart';
import 'widgets/todo_main_view.dart';

class TodoPlugin extends BasePlugin {
  // 单例实例
  static final TodoPlugin instance = TodoPlugin._();
  
  // 私有构造函数
  TodoPlugin._();

  late TaskController _taskController;
  late ReminderController _reminderController;

  @override
  String get id => 'todo';

  @override
  String get name => 'Todo';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'A comprehensive todo management plugin';

  @override
  String get author => 'Memento Team';

  @override
  IconData get icon => Icons.check_circle_outline;

  @override
  Color get color => Colors.blue;

  @override
  Future<void> initialize() async {
    _taskController = TaskController(storageManager, storageDir);
    _reminderController = ReminderController();

    // 加载默认设置
    await loadSettings({
      'defaultView': 'list', // 'list' or 'grid'
      'defaultSortBy': 'dueDate', // 'dueDate', 'priority', or 'custom'
      'reminderAdvanceTime': 60, // minutes
    });
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件相关服务
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TodoMainView(
      taskController: _taskController,
      reminderController: _reminderController,
    );
  }

  @override
  Future<void> uninstall() async {
    // 清理插件数据
    await storageManager.delete(storageDir);
  }
}