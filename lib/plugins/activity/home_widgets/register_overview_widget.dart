/// 活动插件 - 概览组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'providers.dart';

/// 注册概览小组件（2x2 详细卡片）
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_overview',
      pluginId: 'activity',
      name: 'activity_overviewName'.tr,
      description: 'activity_overviewDescription'.tr,
      icon: Icons.access_time,
      color: Colors.pink,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}
