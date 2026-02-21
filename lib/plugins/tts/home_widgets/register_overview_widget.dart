/// TTS 插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'providers.dart';

/// 注册 TTS 概览小组件（2x2）
void registerTTSOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'tts_overview',
      pluginId: 'tts',
      name: 'tts_overviewName'.tr,
      description: 'tts_overviewDescription'.tr,
      icon: Icons.record_voice_over_outlined,
      color: Colors.purple,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: getTTSAvailableStats,
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
    final availableItems = getTTSAvailableStats(context);

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
