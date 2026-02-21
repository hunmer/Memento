/// 计时器插件 - 概览组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片 - 显示统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'timer_overview',
      pluginId: 'timer',
      name: 'timer_overviewName'.tr,
      description: 'timer_overviewDescription'.tr,
      icon: Icons.timer_outlined,
      color: Colors.blueGrey,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}

/// 构建 2x2 详细卡片组件
Widget buildOverviewWidget(
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
      pluginId: 'timer',
      pluginName: 'timer_name'.tr,
      pluginIcon: Icons.timer,
      pluginDefaultColor: Colors.blueGrey,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
