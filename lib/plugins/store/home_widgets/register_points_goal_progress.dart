/// 积分商店插件 - 积分目标进度注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/store/store_plugin.dart';

/// 积分目标进度小组件（基于 LiveSelectorWidget）
///
/// 默认显示 segmentedProgressCard 公共小组件，支持实时更新
class _PointsGoalProgressLiveWidget extends LiveSelectorWidget {
  const _PointsGoalProgressLiveWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'store_cache_updated',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    return _provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'PointsGoalProgressWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 提供积分目标进度公共小组件数据
Future<Map<String, Map<String, dynamic>>> _provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
  if (plugin == null) return {};

  final pointsLogs = plugin.controller.pointsLogs.map((l) => l.toJson()).toList();
  final todayPoints = _calculateTodayPoints(pointsLogs);
  final defaultGoal = 100;

  return {
    'pointsGoalCard': {
      'todayPoints': todayPoints,
      'goal': defaultGoal,
      'isCompleted': todayPoints >= defaultGoal,
    },
  };
}

/// 计算今日获得的积分
int _calculateTodayPoints(List<Map<String, dynamic>> pointsLogs) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return pointsLogs
      .where((log) {
        final timestamp = DateTime.parse(log['timestamp'] as String);
        return timestamp.isAfter(startOfDay) &&
            timestamp.isBefore(endOfDay) &&
            log['type'] == '获得';
      })
      .fold(0, (sum, log) => sum + (log['value'] as int));
}

/// 注册积分目标进度小组件（公共小组件，无配置）
void registerPointsGoalProgressWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'store_points_goal_progress',
      pluginId: 'store',
      name: '积分目标进度',
      description: '显示今日积分与目标的进度',
      icon: Icons.flag,
      color: Colors.orange,
      defaultSize: const MediumSize(), // 2x1
      supportedSizes: [
        const MediumSize(), // 2x1
        const LargeSize(), // 2x2
      ],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: _provideCommonWidgets,
      builder: (context, config) {
        return _PointsGoalProgressLiveWidget(
          config: _ensureConfigHasCommonWidget(config, CommonWidgetId.pointsGoalCard),
          widgetDefinition: registry.getWidget('store_points_goal_progress')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(
  Map<String, dynamic> config,
  CommonWidgetId defaultWidgetId,
) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': defaultWidgetId.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
