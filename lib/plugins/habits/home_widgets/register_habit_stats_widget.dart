/// 习惯追踪插件 - 习惯统计小组件注册
///
/// 支持指定习惯配置，显示单个习惯的详细统计
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart' show pluginColor;
import 'providers.dart' show provideHabitStatsWidgets;

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
                widgetDefinition: registry.getWidget('habits_habit_stats')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
