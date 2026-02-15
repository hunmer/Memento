/// 习惯追踪插件 - 热力图选择器组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'providers.dart';
import 'widgets/habit_heatmap_widget.dart';

/// 导航到习惯详情页（显示计时器对话框）
void _navigateToHabitDetail(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data is Map<String, dynamic>
      ? result.data as Map<String, dynamic>
      : {};
  final habitId = data['id'] as String?;

  if (habitId != null) {
    // 使用路由跳转到习惯计时器页面
    NavigationHelper.pushNamed(
      context,
      '/habit/timer',
      arguments: {'habitId': habitId, 'action': 'show_dialog'},
    );
  }
}

/// 渲染习惯热力图数据（适配器）
Widget _renderHabitHeatmapData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  return StatefulBuilder(
    builder: (context, setState) {
      return renderHabitHeatmapData(
        context,
        result,
        config,
        setState,
        navigateToHabitDetail: _navigateToHabitDetail,
      );
    },
  );
}

/// 注册习惯热力图选择器组件
void registerHabitHeatmapWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'habits_habit_heatmap',
      pluginId: 'habits',
      name: 'habits_heatmapWidgetName'.tr,
      description: 'habits_heatmapWidgetDescription'.tr,
      icon: Icons.calendar_today,
      color: Colors.amber,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'habits.habit',
      dataRenderer: _renderHabitHeatmapData,
      navigationHandler: _navigateToHabitDetail,
      dataSelector: extractHabitHeatmapData,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('habits_habit_heatmap')!,
        config: config,
      ),
    ),
  );
}
