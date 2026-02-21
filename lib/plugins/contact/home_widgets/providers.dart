/// 联系人插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import '../contact_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  return [
    StatItemData(
      id: 'total_contacts',
      label: 'contact_totalContacts'.tr,
      value: '0',
      highlight: false,
    ),
    StatItemData(
      id: 'recent_contacts',
      label: 'contact_recentContacts'.tr,
      value: '0',
      highlight: false,
      color: Colors.green,
    ),
  ];
}

/// 异步加载联系人统计数据
Future<List<StatItemData>> loadContactStats(BuildContext context) async {
  try {
    final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
    if (plugin == null) return getAvailableStats(context);

    final controller = plugin.controller;
    final contacts = await controller.getAllContacts();
    final recentCount = await controller.getRecentlyContactedCount();

    return [
      StatItemData(
        id: 'total_contacts',
        label: 'contact_totalContacts'.tr,
        value: '${contacts.length}',
        highlight: false,
      ),
      StatItemData(
        id: 'recent_contacts',
        label: 'contact_recentContacts'.tr,
        value: '$recentCount',
        highlight: recentCount > 0,
        color: Colors.green,
      ),
    ];
  } catch (e) {
    return getAvailableStats(context);
  }
}

/// 构建概览小组件
Widget buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
  try {
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

    return FutureBuilder<List<StatItemData>>(
      future: loadContactStats(context),
      builder: (context, snapshot) {
        final availableItems = snapshot.data ?? getAvailableStats(context);

        return GenericPluginWidget(
          pluginId: 'contact',
          pluginName: 'contact_name'.tr,
          pluginIcon: Icons.contacts,
          pluginDefaultColor: Colors.deepPurple,
          availableItems: availableItems,
          config: widgetConfig,
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
