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
import 'timer_plugin.dart';

/// 计时器插件的主页小组件注册
class TimerHomeWidgets {
  /// 注册所有计时器插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'timer_icon',
      pluginId: 'timer',
      name: 'timer_widgetName'.tr,
      description: 'timer_widgetDescription'.tr,
      icon: Icons.timer,
      color: Colors.blueGrey,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.timer,
        color: Colors.blueGrey,
        name: 'timer_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'timer_overview',
      pluginId: 'timer',
      name: 'timer_overviewName'.tr,
      description: 'timer_overviewDescription'.tr,
      icon: Icons.timer_outlined,
      color: Colors.blueGrey,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));

    // 计时器选择器小组件 - 快速访问指定计时器详情
    registry.register(HomeWidget(
      id: 'timer_task_selector',
      pluginId: 'timer',
      name: 'timer_quickAccess'.tr,
      description: 'timer_quickAccessDesc'.tr,
      icon: Icons.timer,
      color: Colors.blueGrey,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      selectorId: 'timer.task',
      dataRenderer: _renderTimerData,
      navigationHandler: _navigateToTimerDetail,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('timer_task_selector')!,
        config: config,
      ),
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return [];

      final tasks = plugin.getTasks();
      final totalCount = tasks.length;
      final runningCount = tasks.where((task) => task.isRunning).length;

      return [
        StatItemData(
          id: 'total_count',
          label: 'timer_totalTimer'.tr,
          value: '$totalCount',
          highlight: false,
        ),
        StatItemData(
          id: 'running_count',
          label: 'timer_running'.tr,
          value: '$runningCount',
          highlight: runningCount > 0,
          color: Colors.blueGrey,
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
        pluginId: 'timer',
        pluginName: 'timer_name'.tr,
        pluginIcon: Icons.timer,
        pluginDefaultColor: Colors.blueGrey,
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

  // ===== 计时器选择器小组件相关方法 =====

  /// 渲染计时器数据
  static Widget _renderTimerData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final taskData = result.data as Map<String, dynamic>;
    final name = taskData['name'] as String? ?? '未知计时器';
    final group = taskData['group'] as String? ?? '默认';
    final colorValue = taskData['color'] as int? ?? 4284513675;
    final isRunning = taskData['isRunning'] as bool? ?? false;

    final taskColor = Color(colorValue);

    // 获取计时器信息
    final timerItems = taskData['timerItems'] as List? ?? [];
    String timerInfo = '';
    if (timerItems.isNotEmpty) {
      final firstTimer = timerItems.first;
      final type = firstTimer['type'] as int? ?? 0;
      final duration = firstTimer['duration'] as int? ?? 0;

      switch (type) {
        case 0: // 正计时
          timerInfo = '正计时';
          break;
        case 1: // 倒计时
          timerInfo = '倒计时 ${duration}s';
          break;
        case 2: // 番茄钟
          timerInfo = '番茄钟';
          break;
      }
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
                  Icons.timer,
                  size: 20,
                  color: taskColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRunning ? '运行中' : '已停止',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isRunning ? Colors.green : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: taskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: taskColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timerInfo.isNotEmpty)
                        Text(
                          timerInfo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const Spacer(),
                Text(
                  'viewDetail'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到计时器详情页面
  static void _navigateToTimerDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final taskData = result.data as Map<String, dynamic>;
    final taskId = taskData['id'] as String?;

    if (taskId != null) {
      NavigationHelper.pushNamed(
        context,
        '/timer',
        arguments: {'taskId': taskId},
      );
    }
  }
}
