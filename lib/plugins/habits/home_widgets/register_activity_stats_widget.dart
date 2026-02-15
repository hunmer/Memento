/// 习惯追踪插件 - 活动统计小组件注册
///
/// 支持日期范围（本日/本周/本月/本年）和显示数量配置
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart' show pluginColor;
import 'providers.dart' show provideActivityStatsWidgets;

/// 注册活动统计小组件
void registerActivityStatsWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'habits_activity_stats',
      pluginId: 'habits',
      name: 'habits_activityStatsName'.tr,
      description: 'habits_activityStatsDescription'.tr,
      icon: Icons.analytics,
      color: pluginColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      selectorId: 'habits.activity_stats.config',
      commonWidgetsProvider: provideActivityStatsWidgets,

      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'habit_data_changed',
                'habit_completion_record_saved',
                'habit_timer_stopped',
              ],
              onEvent: () => setState(() {}),
              child: GenericSelectorWidget(
                widgetDefinition: registry.getWidget('habits_activity_stats')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
