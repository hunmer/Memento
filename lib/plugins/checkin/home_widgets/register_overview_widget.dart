/// 打卡插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../checkin_plugin.dart';

/// 注册 2x2 详细卡片组件
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_overview',
      pluginId: 'checkin',
      name: 'checkin_overviewName'.tr,
      description: 'checkin_overviewDescription'.tr,
      icon: Icons.checklist_rtl,
      color: Colors.teal,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ),
  );
}

/// 获取可用的统计项
List<StatItemData> _getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
    if (plugin == null) return [];

    final todayCheckins = plugin.getTodayCheckins();
    final totalItems = plugin.checkinItems.length;
    final totalCheckins = plugin.getTotalCheckins();

    return [
      StatItemData(
        id: 'today_checkin',
        label: 'checkin_todayCheckin'.tr,
        value: '$todayCheckins/$totalItems',
        highlight: todayCheckins > 0,
        color: Colors.teal,
      ),
      StatItemData(
        id: 'total_count',
        label: 'checkin_totalCheckinCount'.tr,
        value: '$totalCheckins',
        highlight: false,
      ),
    ];
  } catch (e) {
    return [];
  }
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
    final availableItems = _getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'checkin',
      pluginName: 'checkin_name'.tr,
      pluginIcon: Icons.checklist,
      pluginDefaultColor: Colors.teal,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
