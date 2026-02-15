import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:get/get.dart';

/// NFC插件的主页小组件注册
class NfcHomeWidgets {
  /// 注册所有NFC插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'nfc_icon',
      pluginId: 'nfc',
      name: 'nfc_widgetName'.tr,
      description: 'nfc_widgetDescription'.tr,
      icon: Icons.nfc,
      color: Colors.orange,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.nfc,
        color: Colors.orange,
        name: 'nfc_pluginName'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示NFC状态
    registry.register(HomeWidget(
      id: 'nfc_overview',
      pluginId: 'nfc',
      name: 'nfc_overviewName'.tr,
      description: 'nfc_overviewDescription'.tr,
      icon: Icons.nfc_outlined,
      color: Colors.orange,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    // NFC 状态需要在运行时检查，这里只显示基本信息
    return [
      StatItemData(
        id: 'nfc_status',
        label: 'NFC',
        value: 'nfc_pluginName'.tr,
        highlight: true,
        color: Colors.orange,
      ),
    ];
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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
        pluginId: 'nfc',
        pluginName: 'nfc_pluginName'.tr,
        pluginIcon: Icons.nfc,
        pluginDefaultColor: Colors.orange,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }
}
