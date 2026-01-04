import 'package:Memento/core/app_initializer.dart';
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
import 'package:Memento/widgets/event_listener_container.dart';
import 'tracker_plugin.dart';

/// 目标追踪插件的主页小组件注册
class TrackerHomeWidgets {
  /// 注册所有目标追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'tracker_icon',
        pluginId: 'tracker',
        name: 'tracker_widgetName'.tr,
        description: 'tracker_widgetDescription'.tr,
        icon: Icons.track_changes,
        color: Colors.red,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.track_changes,
              color: Colors.red,
              name: 'tracker_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'view',
        pluginId: 'tracker',
        name: 'tracker_overviewName'.tr,
        description: 'tracker_overviewDescription'.tr,
        icon: Icons.analytics_outlined,
        color: Colors.red,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 目标选择器小组件 - 快速访问指定目标详情
    registry.register(
      HomeWidget(
        id: 'tracker_goal_selector',
        pluginId: 'tracker',
        name: 'tracker_quickAccess'.tr,
        description: 'tracker_quickAccessDesc'.tr,
        icon: Icons.track_changes,
        color: Colors.red,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'tracker.goal',
        dataRenderer: _renderGoalData,
        navigationHandler: _navigateToGoalDetail,
        dataSelector: _extractGoalData,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('tracker_goal_selector')!,
              config: config,
            ),
      ),
    );
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractGoalData(List<dynamic> dataArray) {
    Map<String, dynamic> itemData = {};
    final rawData = dataArray[0];

    if (rawData is Map<String, dynamic>) {
      itemData = rawData;
    } else if (rawData is dynamic && rawData.toJson != null) {
      final jsonResult = rawData.toJson();
      if (jsonResult is Map<String, dynamic>) {
        itemData = jsonResult;
      }
    }

    final result = <String, dynamic>{};
    result['id'] = itemData['id'] as String?;
    result['name'] = itemData['name'] as String?;
    result['icon'] = itemData['icon'] as String?;
    result['iconColor'] = itemData['iconColor'] as int?;
    result['currentValue'] = itemData['currentValue'] as double?;
    result['targetValue'] = itemData['targetValue'] as double?;
    result['unitType'] = itemData['unitType'] as String?;
    return result;
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) return [];

      final controller = plugin.controller;
      final todayComplete = controller.getTodayCompletedGoals();
      final monthComplete = controller.getMonthCompletedGoals();

      return [
        StatItemData(
          id: 'today_complete',
          label: 'tracker_todayComplete'.tr,
          value: '$todayComplete',
          highlight: todayComplete > 0,
        ),
        StatItemData(
          id: 'month_complete',
          label: 'tracker_thisMonthComplete'.tr,
          value: '$monthComplete',
          highlight: monthComplete > 0,
          color: Colors.red,
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

      // 获取基础统计项数据
      final baseItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'tracker',
        pluginName: 'tracker_name'.tr,
        pluginIcon: Icons.track_changes,
        pluginDefaultColor: Colors.red,
        availableItems: baseItems,
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

  // ===== 目标选择器小组件相关方法 =====

  /// 渲染目标数据
  static Widget _renderGoalData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从初始化数据中获取目标ID
    final goalData = result.data as Map<String, dynamic>;
    final goalId = goalData['id'] as String?;

    if (goalId == null) {
      return _buildErrorWidget(context, 'tracker_goalNotFound'.tr);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['tracker_record_added'],
          onEvent: () => setState(() {}),
          child: _buildGoalWidget(context, goalId),
        );
      },
    );
  }

  /// 构建目标小组件内容（获取最新数据）
  static Widget _buildGoalWidget(BuildContext context, String goalId) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的目标数据
    final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, 'tracker_pluginNotAvailable'.tr);
    }

    // 查找对应目标
    final goal = plugin.controller.goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw Exception('tracker_goalNotFound'.tr),
    );

    // 使用最新的目标数据
    final name = goal.name;
    final currentValue = goal.currentValue;
    final targetValue = goal.targetValue;
    final unitType = goal.unitType;
    final iconCode = goal.icon;
    final iconColorValue = goal.iconColor;

    final progress = (targetValue > 0 ? (currentValue / targetValue) : 0).clamp(
      0.0,
      1.0,
    );
    final goalColor = Color(iconColorValue ?? 4283215696);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目标名称和图标
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(
                        int.tryParse(iconCode) ?? 57455,
                        fontFamily: 'MaterialIcons',
                      ),
                      color: goalColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$currentValue / $targetValue $unitType',
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
              // 进度条和百分比
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.toDouble(),
                        minHeight: 8,
                        backgroundColor: goalColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progress >= 1.0 ? Colors.green : goalColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到目标详情页面
  static void _navigateToGoalDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final goalData = result.data[0] as Map<String, dynamic>;
    // id 可能是 int 或 String，需要统一处理
    final goalId = goalData['id']?.toString();

    if (goalId != null) {
      // 使用 navigatorKey.currentContext 确保导航正常工作
      final navContext = navigatorKey.currentContext ?? context;
      NavigationHelper.pushNamed(
        navContext,
        '/tracker',
        arguments: {'goalId': goalId},
      );
    }
  }
}
