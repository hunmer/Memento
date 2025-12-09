import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'day_plugin.dart';
import 'l10n/day_localizations.dart';

/// 纪念日插件的主页小组件注册
class DayHomeWidgets {
  /// 注册所有纪念日插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'day_icon',
      pluginId: 'day',
      name: '纪念日',
      description: '快速打开纪念日',
      icon: Icons.event_outlined,
      color: Colors.black87,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'day_overview',
      pluginId: 'day',
      name: '纪念日概览',
      description: '显示纪念日总数和即将到来的事件',
      icon: Icons.event,
      color: Colors.black87,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
      if (plugin == null) return [];

      final totalCount = plugin.getMemorialDayCount();
      final upcomingDays = plugin.getUpcomingMemorialDays();
      final l10n = DayLocalizations.of(context);
      return [
        StatItemData(
          id: 'total_count',
          label: l10n.memorialDays,
          value: '$totalCount',
          highlight: false,
        ),
        StatItemData(
          id: 'upcoming',
          label: l10n.upcoming,
          value: upcomingDays.isNotEmpty ? upcomingDays.join('、') : '暂无',
          highlight: upcomingDays.isNotEmpty,
          color: Colors.black87,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return const GenericIconWidget(
      icon: Icons.event_outlined,
      color: Colors.black87,
      name: '纪念日',
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = DayLocalizations.of(context);

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
        pluginName: l10n.name,
        pluginIcon: Icons.event_outlined,
        pluginDefaultColor: Colors.black87,
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
