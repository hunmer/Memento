/// 日历插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart' as hw;
import 'providers.dart';

/// 日历插件颜色
const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

/// 注册概览组件
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_overview',
      pluginId: 'calendar',
      name: 'calendar_overviewName'.tr,
      description: 'calendar_overviewDescription'.tr,
      icon: Icons.calendar_today,
      color: _calendarColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: (context) => getAvailableStats(context),
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
      pluginId: 'calendar',
      pluginName: 'calendar_name'.tr,
      pluginIcon: Icons.calendar_month,
      pluginDefaultColor: _calendarColor,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return hw.HomeWidget.buildErrorWidget(context, e.toString());
  }
}
