/// 目标追踪插件 - 目标选择器组件注册（快速访问指定目标详情）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'providers.dart';
import 'widgets.dart';

/// 注册目标选择器小组件
void registerGoalSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'tracker_goal_selector',
      pluginId: 'tracker',
      name: 'tracker_quickAccess'.tr,
      description: 'tracker_quickAccessDesc'.tr,
      icon: Icons.track_changes,
      color: Colors.red,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'tracker.goal',
      dataRenderer: renderGoalData,
      navigationHandler: navigateToGoalDetail,
      dataSelector: extractGoalData,

      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,

      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('tracker_goal_selector')!,
        config: config,
      ),
    ),
  );
}
