/// 习惯追踪插件 - 习惯统计小组件注册（基于 LiveSelectorWidget）
///
/// 支持指定习惯配置，显示单个习惯的详细统计
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'utils.dart' show pluginColor;
import 'providers.dart' show provideHabitStatsWidgets;
import 'widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';

/// 导航到习惯插件
void _navigateToHabits(BuildContext context, SelectorResult result) {
  final plugin = PluginManager.instance.getPlugin('habits');
  if (plugin == null) return;

  // 记录插件打开历史
  PluginManager.instance.recordPluginOpen(plugin);

  // 跳转到习惯插件
  NavigationHelper.openContainerWithHero(
    context,
    (_) => plugin.buildMainView(context),
    heroTag: 'habits_habit_stats',
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// 习惯统计小组件（基于 LiveSelectorWidget）
///
/// 显示单个习惯的详细统计，支持实时更新
class HabitStatsWidget extends LiveSelectorWidget {
  const HabitStatsWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'habit_completion_record_saved', // 完成记录保存事件
    'habit_timer_stopped', // 计时器停止事件
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    try {
      // 获取 selectorWidgetConfig
      final selectorWidgetConfig = config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorWidgetConfig == null) {
        debugPrint('[HabitStatsWidget] No selectorWidgetConfig');
        return {};
      }

      // 解析 SelectorWidgetConfig，提取 habitId 和 commonWidgetId
      final parsedConfig = SelectorWidgetConfig.fromJson(selectorWidgetConfig);
      final habitId = HabitStatsWidgetConfig.extractHabitId(selectorWidgetConfig);

      if (habitId == null || habitId.isEmpty) {
        debugPrint('[HabitStatsWidget] No habitId in selectorWidgetConfig: $selectorWidgetConfig');
        return {};
      }

      // 调用 provider 获取实时数据，包含 commonWidgetId
      final data = <String, dynamic>{'habitId': habitId};
      if (parsedConfig.commonWidgetId != null) {
        data['commonWidgetId'] = parsedConfig.commonWidgetId!;
      }
      if (parsedConfig.commonWidgetProps != null) {
        data['commonWidgetProps'] = parsedConfig.commonWidgetProps!;
      }

      return provideHabitStatsWidgets(data);
    } catch (e) {
      debugPrint('[HabitStatsWidget] 获取数据失败: $e');
      debugPrint('[HabitStatsWidget] config: $config');
      return {};
    }
  }

  @override
  String get widgetTag => 'HabitStatsWidget';
}

/// 注册习惯统计小组件
void registerHabitStatsWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'habits_habit_stats',
      pluginId: 'habits',
      name: 'habits_habitStatsName'.tr,
      description: 'habits_habitStatsDescription'.tr,
      icon: Icons.trending_up,
      color: pluginColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      selectorId: 'habits.habit_stats.config',
      commonWidgetsProvider: provideHabitStatsWidgets,
      navigationHandler: _navigateToHabits,

      builder: (context, config) {
        return HabitStatsWidget(
          config: config,
          widgetDefinition: registry.getWidget('habits_habit_stats')!,
        );
      },
    ),
  );
}
