import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'tts_plugin.dart';
import 'package:get/get.dart';

/// TTS插件的主页小组件注册
class TtsHomeWidgets {
  /// 注册所有TTS插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'tts_icon',
      pluginId: 'tts',
      name: 'tts_widgetName'.tr,
      description: 'tts_widgetDescription'.tr,
      icon: Icons.record_voice_over,
      color: Colors.purple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.record_voice_over,
        color: Colors.purple,
        name: 'tts_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示TTS状态
    registry.register(HomeWidget(
      id: 'tts_overview',
      pluginId: 'tts',
      name: 'tts_overviewName'.tr,
      description: 'tts_overviewDescription'.tr,
      icon: Icons.record_voice_over_outlined,
      color: Colors.purple,
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
      final plugin = PluginManager.instance.getPlugin('tts') as TTSPlugin?;
      if (plugin == null) return [];

      final manager = plugin.managerService;
      int serviceCount = 0;
      int enabledCount = 0;

      // 同步获取服务数量
      manager.getAllServices().then((services) {
        serviceCount = services.length;
        enabledCount = services.where((s) => s.isEnabled).length;
      });

      final queueCount = plugin.queue.length;

      return [
        StatItemData(
          id: 'total_services',
          label: 'tts_servicesList'.tr,
          value: '$serviceCount',
          highlight: serviceCount > 0,
          color: Colors.purple,
        ),
        StatItemData(
          id: 'enabled_services',
          label: 'tts_enabled'.tr,
          value: '$enabledCount',
          highlight: enabledCount > 0,
          color: Colors.green,
        ),
        StatItemData(
          id: 'queue_count',
          label: 'tts_queue'.tr,
          value: '$queueCount',
          highlight: queueCount > 0,
          color: Colors.orange,
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
        pluginId: 'tts',
        pluginName: 'tts_name'.tr,
        pluginIcon: Icons.record_voice_over,
        pluginDefaultColor: Colors.purple,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }
}
