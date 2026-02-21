/// WebView插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/webview/webview_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
    if (plugin == null) return [];

    final cardsCount = plugin.getTotalCardsCount();
    final tabsCount = plugin.getActiveTabsCount();

    return [
      StatItemData(
        id: 'total_cards',
        label: 'webview_cards'.tr,
        value: '$cardsCount',
        highlight: cardsCount > 0,
        color: const Color(0xFF4285F4),
      ),
      StatItemData(
        id: 'active_tabs',
        label: 'webview_tabs'.tr,
        value: '$tabsCount',
        highlight: tabsCount > 0,
        color: Colors.green,
      ),
    ];
  } catch (e) {
    return [];
  }
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
      pluginId: 'webview',
      pluginName: 'webview_name'.tr,
      pluginIcon: Icons.language,
      pluginDefaultColor: const Color(0xFF4285F4),
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
