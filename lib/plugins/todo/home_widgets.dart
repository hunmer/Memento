import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'todo_plugin.dart';

/// 待办事项插件的主页小组件注册
class TodoHomeWidgets {
  /// 注册所有待办事项插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'todo_icon',
      pluginId: 'todo',
      name: 'todo_widgetName'.tr,
      description: 'todo_widgetDescription'.tr,
      icon: Icons.check_box,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.check_box,
        color: Colors.blue,
        name: 'todo_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
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
    ));

    // 任务选择器小组件 - 快速添加新任务
    registry.register(HomeWidget(
      id: 'todo_task_selector',
      pluginId: 'todo',
      name: 'todo_quickAdd'.tr,
      description: 'todo_quickAddDesc'.tr,
      icon: Icons.add_task,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      selectorId: 'todo.task',
      dataRenderer: _renderTaskData,
      navigationHandler: _navigateToAddTask,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('todo_task_selector')!,
        config: config,
      ),
    ));
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
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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

  // ===== 任务选择器小组件相关方法 =====

  /// 渲染任务数据
  static Widget _renderTaskData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final taskData = result.data as Map<String, dynamic>;
    final title = taskData['title'] as String? ?? '新任务';
    final priority = taskData['priority'] as int? ?? 1;
    final status = taskData['status'] as int? ?? 0;

    // 优先级颜色
    Color priorityColor;
    switch (priority) {
      case 0: priorityColor = Colors.green; break;
      case 2: priorityColor = Colors.red; break;
      default: priorityColor = Colors.orange;
    }

    // 状态图标
    IconData statusIcon;
    switch (status) {
      case 1: statusIcon = Icons.play_circle_outline; break;
      case 2: statusIcon = Icons.check_circle_outline; break;
      default: statusIcon = Icons.radio_button_unchecked;
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'todo_quickAdd'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        status == 0 ? '待办' : (status == 1 ? '进行中' : '已完成'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: priorityColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到添加任务页面
  static void _navigateToAddTask(
    BuildContext context,
    SelectorResult result,
  ) {
    // 跳转到待办事项页面
    NavigationHelper.pushNamed(
      context,
      '/todo',
      arguments: {'action': 'create'},
    );
  }
}
