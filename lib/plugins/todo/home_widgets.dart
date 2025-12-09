import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
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
}
