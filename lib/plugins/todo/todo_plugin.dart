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

  // 获取所有待办数量
  int getTotalTasks() {
    return TodoService.getInstance(storage).tasks.length;
  }

  // 获取七日内的待办数量（开始日期到今天不超过7天的任务）
  int getRecentTasks() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return TodoService.getInstance(storage).tasks.where((task) {
      if (task.startDate == null) return false;
      return task.startDate!.isAfter(sevenDaysAgo) &&
          task.startDate!.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = getTotalTasks();
    final recentTasks = getRecentTasks();

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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon ?? Icons.check_circle_outline,
                  size: 24,
                  color: color ?? theme.primaryColor,
                ),
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

          // 统计信息卡片
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 所有待办数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('所有待办', style: theme.textTheme.bodyMedium),
                    Text(
                      '$totalTasks',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 七日待办数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('七日待办', style: theme.textTheme.bodyMedium),
                    Text(
                      '$recentTasks',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            recentTasks > 0 ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
