/// 笔记插件 - 概览统计组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../notes_plugin.dart';
import 'utils.dart' show notesColor;

/// 注册概览统计小组件（2x2 详细卡片 - 显示统计信息）
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_overview',
      pluginId: 'notes',
      name: 'notes_overviewName'.tr,
      description: 'notes_overviewDescription'.tr,
      icon: Icons.notes,
      color: notesColor,
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
    final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
    if (plugin == null) return [];

    final totalNotes = plugin.getTotalNotesCount();
    final recentNotes = plugin.getRecentNotesCount();

    return [
      StatItemData(
        id: 'total_notes',
        label: '总笔记数',
        value: '$totalNotes',
        highlight: false,
      ),
      StatItemData(
        id: 'recent_notes',
        label: '最近笔记',
        value: '$recentNotes',
        highlight: recentNotes > 0,
        color: notesColor,
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
      pluginId: 'notes',
      pluginName: 'notes_name'.tr,
      pluginIcon: Icons.notes,
      pluginDefaultColor: notesColor,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
