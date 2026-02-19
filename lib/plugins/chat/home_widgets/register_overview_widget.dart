/// 聊天插件 - 概览组件注册
///
/// 注册 2x2 详细卡片组件，显示统计信息
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'builders.dart';
import 'providers.dart';

/// 注册聊天概览组件
///
/// 这是一个 2x2 的大卡片组件，显示聊天统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'chat_overview',
      pluginId: 'chat',
      name: 'chat_overviewName'.tr,
      description: 'chat_overviewDescription'.tr,
      icon: Icons.chat_bubble_outline,
      color: Colors.indigoAccent,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryCommunication'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}
