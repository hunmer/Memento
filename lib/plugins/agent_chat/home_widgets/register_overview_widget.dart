/// Agent Chat - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片 - 显示统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'agent_chat_overview',
      pluginId: 'agent_chat',
      name: 'agent_chat_overview'.tr,
      description: 'agent_chat_overviewDescription'.tr,
      icon: Icons.analytics_outlined,
      color: const Color(0xFF2196F3),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}

/// 构建 2x2 详细卡片组件
Widget _buildOverviewWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取基础统计项数据
    final baseItems = getAvailableStats(context);

    // 使用GetX翻译更新统计项标签
    final availableItems = baseItems;

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'agent_chat',
      pluginName: 'agent_chat_name'.tr,
      pluginIcon: Icons.chat_bubble_outline,
      pluginDefaultColor: const Color(0xFF2196F3),
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
