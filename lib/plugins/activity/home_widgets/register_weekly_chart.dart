/// 活动插件 - 七天图表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';

/// 注册七天活动统计图表小组件
void registerWeeklyChartWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_weekly_chart',
      pluginId: 'activity',
      name: '七天活动统计',
      description: '展示近七天的活动时长统计，支持多种图表样式',
      icon: Icons.bar_chart,
      color: Colors.pink,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
      category: 'home_categoryRecord'.tr,
      commonWidgetsProvider: provideWeeklyChartWidgets,
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
              child: buildCommonWidgetsWidget(context, config),
            );
          },
        );
      },
    ),
  );
}
