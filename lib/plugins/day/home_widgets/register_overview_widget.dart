/// 纪念日插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片组件 - 显示统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_overview',
      pluginId: 'day',
      name: 'day_overviewName'.tr,
      description: 'day_overviewDescription'.tr,
      icon: Icons.event,
      color: Colors.black87,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryRecord'.tr,
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

    // 获取可用的统计项数据
    final availableItems = getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'day',
      pluginName: 'day_name'.tr,
      pluginIcon: Icons.event_outlined,
      pluginDefaultColor: Colors.black87,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
