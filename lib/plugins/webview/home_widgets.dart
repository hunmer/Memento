import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'webview_plugin.dart';
import 'package:get/get.dart';

/// WebView插件的主页小组件注册
class WebviewHomeWidgets {
  /// 注册所有WebView插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'webview_icon',
      pluginId: 'webview',
      name: 'webview_widgetName'.tr,
      description: 'webview_widgetDescription'.tr,
      icon: Icons.language,
      color: const Color(0xFF4285F4),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.language,
        color: const Color(0xFF4285F4),
        name: 'webview_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示浏览器统计
    registry.register(HomeWidget(
      id: 'webview_overview',
      pluginId: 'webview',
      name: 'webview_overviewName'.tr,
      description: 'webview_overviewDescription'.tr,
      icon: Icons.language_outlined,
      color: const Color(0xFF4285F4),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
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
        pluginName: 'webview_name'.tr,
        pluginIcon: Icons.language,
        pluginDefaultColor: const Color(0xFF4285F4),
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
