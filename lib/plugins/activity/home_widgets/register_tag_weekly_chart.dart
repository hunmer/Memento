/// 活动插件 - 标签图表组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';

/// 注册标签七天活动统计图表小组件
void registerTagWeeklyChartWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_tag_weekly_chart',
      pluginId: 'activity',
      name: '标签七天统计',
      description: '展示指定标签近七天的活动时长统计，支持多种图表样式',
      icon: Icons.tag,
      color: Colors.pink,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
      category: 'home_categoryRecord'.tr,
      selectorId: 'activity.tag',
      commonWidgetsProvider: provideTagWeeklyChartWidgets,
      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'activity_added',
                'activity_updated',
                'activity_deleted',
              ],
              onEvent: () => setState(() {}),
              child: buildTagCommonWidget(context, config),
            );
          },
        );
      },
    ),
  );
}
