import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'tracker_plugin.dart';

/// 目标追踪插件的主页小组件注册
class TrackerHomeWidgets {
  /// 注册所有目标追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'tracker_icon',
      pluginId: 'tracker',
      name: 'Goal Tracker',
      description: 'Quick access to Goal Tracker',
      icon: Icons.track_changes,
      color: Colors.red,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.track_changes,
        color: Colors.red,
        name: 'Goal Tracker',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'tracker_overview',
      pluginId: 'tracker',
      name: 'Goal Tracker Overview',
      description: 'Display today and monthly completion statistics',
      icon: Icons.analytics_outlined,
      color: Colors.red,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
    try {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) return [];

      final controller = plugin.controller;
      final todayComplete = controller.getTodayCompletedGoals();
      final monthComplete = controller.getMonthCompletedGoals();

      // Note: We can't use l10n here as this is a static method without context
      // The labels will be translated in the build method if needed
      return [
        StatItemData(
          id: 'today_complete',
          label: 'Today Complete', // Default English, will be overridden if context available
          value: '$todayComplete',
          highlight: todayComplete > 0,
        ),
        StatItemData(
          id: 'month_complete',
          label: 'Month Complete', // Default English
          value: '$monthComplete',
          highlight: monthComplete > 0,
          color: Colors.red,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = TrackerLocalizations.of(context);

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

      // 获取基础统计项数据
      final baseItems = _getAvailableStats();

      // 使用l10n更新统计项标签
      final availableItems = baseItems.map((item) {
        if (item.id == 'today_complete') {
          return StatItemData(
            id: item.id,
            label: l10n.todayComplete,
            value: item.value,
            highlight: item.highlight,
            color: item.color,
          );
        } else if (item.id == 'month_complete') {
          return StatItemData(
            id: item.id,
            label: l10n.thisMonthComplete,
            value: item.value,
            highlight: item.highlight,
            color: item.color,
          );
        }
        return item;
      }).toList();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.track_changes,
        pluginDefaultColor: Colors.red,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    final l10n = TrackerLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            l10n.loadFailed,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
