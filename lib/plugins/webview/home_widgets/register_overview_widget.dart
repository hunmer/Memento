/// WebView插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片组件 - 显示浏览器统计
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'webview_overview',
      pluginId: 'webview',
      name: 'webview_overviewName'.tr,
      description: 'webview_overviewDescription'.tr,
      icon: Icons.language_outlined,
      color: const Color(0xFF4285F4),
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}
