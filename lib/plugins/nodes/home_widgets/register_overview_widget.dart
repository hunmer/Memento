/// 节点笔记本插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'providers.dart';

/// 注册概览组件（2x2 详细卡片 - 显示统计信息）
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'nodes_overview',
      pluginId: 'nodes',
      name: 'nodes_overviewName'.tr,
      description: 'nodes_overviewDescription'.tr,
      icon: Icons.dashboard,
      color: Colors.amber,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}
