import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'controllers/controllers.dart';
import 'views/todo_main_view.dart';

class TodoPlugin extends BasePlugin {
  late TaskController taskController;
  late ReminderController reminderController;
  static TodoPlugin? _instance;
  static TodoPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (_instance == null) {
        throw StateError('TodoPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'todo';

  @override
  String get name => 'Todo';

  @override
  IconData get icon => Icons.check_box;

  @override
  Color get color => Colors.blue;

  @override
  String? getPluginName(context) {
    return TodoLocalizations.of(context).name;
  }

  @override
  Future<void> initialize() async {
    taskController = TaskController(storageManager, storageDir);
    reminderController = ReminderController();

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
    return TodoMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = taskController.getTotalTaskCount();
    final weeklyTasks = taskController.getWeeklyTaskCount();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TodoLocalizations.of(context)!.totalTasksCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$totalTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TodoLocalizations.of(context)!.weeklyTasksCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$weeklyTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<void> uninstall() async {
    // 清理插件数据
    await storageManager.delete(storageDir);
  }
}
