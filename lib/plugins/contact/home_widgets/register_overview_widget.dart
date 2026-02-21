/// 联系人插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片 - 显示统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'contact_overview',
      pluginId: 'contact',
      name: 'contact_overviewName'.tr,
      description: 'contact_overviewDescription'.tr,
      icon: Icons.people,
      color: Colors.deepPurple,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}
