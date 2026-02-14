import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';

/// 注册 2x2 详细卡片组件
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(HomeWidget(
    id: 'openai_overview',
    pluginId: 'openai',
    name: 'openai_overviewName'.tr,
    description: 'openai_overviewDescription'.tr,
    icon: Icons.psychology,
    color: Colors.deepOrange,
    defaultSize: HomeWidgetSize.large,
    supportedSizes: [HomeWidgetSize.large],
    category: 'home_categoryTools'.tr,
    builder: _buildOverviewWidget,
    availableStatsProvider: getAvailableStats,
  ));
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

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'openai_agent_added',
            'openai_agent_updated',
            'openai_agent_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildOverviewContent(context, widgetConfig),
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 构建概览卡片内容（每次重建时获取最新数据）
Widget _buildOverviewContent(BuildContext context, PluginWidgetConfig widgetConfig) {
  // 获取最新的统计项数据
  final availableItems = getAvailableStats(context);

  // 使用通用小组件
  return GenericPluginWidget(
    pluginId: 'openai',
    pluginName: 'openai_name'.tr,
    pluginIcon: Icons.smart_toy,
    pluginDefaultColor: Colors.deepOrange,
    availableItems: availableItems,
    config: widgetConfig,
  );
}
