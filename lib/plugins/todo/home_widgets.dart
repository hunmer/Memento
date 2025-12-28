import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'todo_plugin.dart';
import 'models/task.dart';

/// 待办事项插件的主页小组件注册
class TodoHomeWidgets {
  /// 注册所有待办事项插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'todo_icon',
        pluginId: 'todo',
        name: 'todo_widgetName'.tr,
        description: 'todo_widgetDescription'.tr,
        icon: Icons.check_box,
        color: Colors.blue,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.check_box,
              color: Colors.blue,
              name: 'todo_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'todo_overview',
        pluginId: 'todo',
        name: 'todo_overviewName'.tr,
        description: 'todo_overviewDescription'.tr,
        icon: Icons.check_box_outlined,
        color: Colors.blue,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 1x1 快速添加任务小组件
    registry.register(
      HomeWidget(
        id: 'todo_quick_add',
        pluginId: 'todo',
        name: 'todo_quickAdd'.tr,
        description: 'todo_quickAddDesc'.tr,
        icon: Icons.add_task,
        color: Colors.blue,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildQuickAddWidget(context),
      ),
    );

    // 2x2 待办列表小组件
    registry.register(
      HomeWidget(
        id: 'todo_list',
        pluginId: 'todo',
        name: 'todo_listWidgetName'.tr,
        description: 'todo_listWidgetDesc'.tr,
        icon: Icons.checklist,
        color: Colors.blue,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildTodoListWidget(context),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) return [];

      final totalTasks = plugin.taskController.getTotalTaskCount();
      final weeklyTasks = plugin.taskController.getWeeklyTaskCount();

      return [
        StatItemData(
          id: 'total_tasks',
          label: 'todo_totalTasks'.tr,
          value: '$totalTasks',
          highlight: false,
        ),
        StatItemData(
          id: 'weekly_tasks',
          label: 'todo_weeklyTasks'.tr,
          value: '$weeklyTasks',
          highlight: weeklyTasks > 0,
          color: Colors.orange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'todo',
        pluginName: 'todo_name'.tr,
        pluginIcon: Icons.check_box,
        pluginDefaultColor: Colors.blue,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 1x1 快速添加小组件 =====

  /// 构建 1x1 快速添加小组件
  static Widget _buildQuickAddWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToAddTask(context),
        child: SizedBox.expand(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标在中间，标题在下边，图标右上角带加号 badge
                  Stack(
                    alignment: Alignment.topRight,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.add_task, size: 40, color: Colors.blue),
                      // 图标右上角加号 badge
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'todo_quickAdd'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 跳转到添加任务页面
  static void _navigateToAddTask(BuildContext context) {
    NavigationHelper.pushNamed(
      context,
      '/todo',
      arguments: {'action': 'create'},
    );
  }

  // ===== 2x2 待办列表小组件 =====

  /// 获取待办任务列表
  static List<Map<String, dynamic>> _getTodoTasks(int limit) {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin != null) {
        final controller = plugin.taskController;
        final tasks = controller.tasks;
        // 获取未完成的任务，按优先级排序
        final pendingTasks =
            tasks.where((t) => t.status != TaskStatus.done).toList()
              ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
        return pendingTasks
            .take(limit)
            .map(
              (task) => {
                'id': task.id,
                'title': task.title,
                'priority': task.priority.index,
                'status': task.status.index,
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[TodoHomeWidgets] 获取任务列表失败: $e');
    }
    return [];
  }

  /// 构建 2x2 待办列表小组件
  static Widget _buildTodoListWidget(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _getTodoTasks(5);

    // 优先级颜色
    Color getPriorityColor(int priority) {
      switch (priority) {
        case 0:
          return Colors.green;
        case 2:
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    // 状态图标
    IconData getStatusIcon(int status) {
      switch (status) {
        case 1:
          return Icons.play_circle_outline;
        case 2:
          return Icons.check_circle_outline;
        default:
          return Icons.radio_button_unchecked;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题
              Row(
                children: [
                  Icon(Icons.checklist, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'todo_name'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 任务列表
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tasks.isNotEmpty) ...[
                        ...tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  getStatusIcon(task['status'] as int),
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    task['title'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          task['status'] as int == 2
                                              ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                                  .withOpacity(0.5)
                                              : theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                      decoration:
                                          task['status'] as int == 2
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: getPriorityColor(
                                      task['priority'] as int,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'empty_todo'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
