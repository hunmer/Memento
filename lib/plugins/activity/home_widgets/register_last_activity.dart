/// 活动插件 - 上次活动组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'widgets/activity_last_activity.dart';

/// 注册上次活动小组件（1x2）
void registerLastActivityWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_last_activity',
      pluginId: 'activity',
      name: '上次活动',
      description: '显示距离上次活动经过的时间和上次活动的时间',
      icon: Icons.history,
      color: Colors.pink,
      defaultSize: HomeWidgetSize.medium, // 2x1
      supportedSizes: [HomeWidgetSize.medium],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => const ActivityLastActivityWidget(),
    ),
  );
}
