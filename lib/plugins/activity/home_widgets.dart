import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'activity_plugin.dart';
import 'l10n/activity_localizations.dart';

/// 活动插件的主页小组件注册
class ActivityHomeWidgets {
  /// 注册所有活动插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'activity_icon',
      pluginId: 'activity',
      name: '活动',
      description: '快速打开活动记录',
      icon: Icons.timeline,
      color: Colors.pink,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.timeline,
        color: Colors.pink,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'activity_overview',
      pluginId: 'activity',
      name: '活动概览',
      description: '显示今日活动数和时长',
      icon: Icons.access_time,
      color: Colors.pink,
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
      final plugin = PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return [];

      final activityCount = plugin.getTodayActivityCountSync();
      final activityDuration = plugin.getTodayActivityDurationSync();
      final remainingTime = plugin.getTodayRemainingTime();

      return [
        StatItemData(
          id: 'today_activities',
          label: '今日活动',
          value: '$activityCount',
          highlight: activityCount > 0,
          color: Colors.pink,
        ),
        StatItemData(
          id: 'today_duration',
          label: '今日时长',
          value: '${(activityDuration / 60).toStringAsFixed(1)}H',
          highlight: false,
        ),
        StatItemData(
          id: 'remaining_time',
          label: '剩余时间',
          value: '${(remainingTime / 60).toStringAsFixed(1)}H',
          highlight: remainingTime < 120,
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
      final l10n = ActivityLocalizations.of(context);

      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        debugPrint('[Activity Widget] 收到的 config: $config');
        if (config.containsKey('pluginWidgetConfig')) {
          debugPrint('[Activity Widget] 找到 pluginWidgetConfig: ${config['pluginWidgetConfig']}');
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
          debugPrint('[Activity Widget] 解析成功，displayStyle: ${widgetConfig.displayStyle}');
        } else {
          debugPrint('[Activity Widget] 未找到 pluginWidgetConfig，使用默认配置');
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        debugPrint('[Activity Widget] 解析配置失败: $e');
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.access_time,
        pluginDefaultColor: Colors.pink,
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
