/// 日历相册插件 - 概览小组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册 2x2 详细卡片 - 显示统计信息
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_album_overview',
      pluginId: 'calendar_album',
      name: 'calendar_album_overview_name'.tr,
      description: 'calendar_album_overview_description'.tr,
      icon: Icons.calendar_today,
      color: pluginColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
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

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'calendar_entry_added',
            'calendar_entry_updated',
            'calendar_entry_deleted',
            'calendar_tag_added',
            'calendar_tag_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildOverviewWidgetContent(context, widgetConfig),
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 构建概览小组件内容（获取最新数据）
Widget _buildOverviewWidgetContent(
  BuildContext context,
  PluginWidgetConfig widgetConfig,
) {
  // 从获取最新的统计项数据
  final availableItems = getAvailableStats(context);

  // 使用通用小组件
  return GenericPluginWidget(
    pluginId: 'calendar_album',
    pluginName: 'calendar_album_name'.tr,
    pluginIcon: Icons.notes_rounded,
    pluginDefaultColor: pluginColor,
    availableItems: availableItems,
    config: widgetConfig,
  );
}
