/// 脚本中心插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'providers.dart';

/// 注册脚本中心概览组件（2x2 详细卡片 - 显示统计信息）
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'scripts_center_overview',
      pluginId: 'scripts_center',
      name: 'scripts_center_overviewName'.tr,
      description: 'scripts_center_overviewDescription'.tr,
      icon: Icons.code_outlined,
      color: Colors.deepPurple,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}

/// 构建 2x2 详细卡片组件
Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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
      pluginId: 'scripts_center',
      pluginName: 'scripts_center_name'.tr,
      pluginIcon: Icons.code,
      pluginDefaultColor: Colors.deepPurple,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
