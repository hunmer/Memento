import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'calendar_plugin.dart';

/// 日历插件的主页小组件注册
class CalendarHomeWidgets {
  /// 注册所有日历插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'calendar_icon',
        pluginId: 'calendar',
        name: 'calendar_widgetName'.tr,
        description: 'calendar_widgetDescription'.tr,
        icon: Icons.calendar_month,
        color: const Color.fromARGB(255, 211, 91, 91),
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.calendar_month,
              color: const Color.fromARGB(255, 211, 91, 91),
              name: 'calendar_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'calendar_overview',
        pluginId: 'calendar',
        name: 'calendar_overviewName'.tr,
        description: 'calendar_overviewDescription'.tr,
        icon: Icons.calendar_today,
        color: const Color.fromARGB(255, 211, 91, 91),
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) return [];

      final allEvents = plugin.controller.getAllEvents();
      final eventCount = allEvents.length;

      // 获取7天内的活动数量

      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      final upcomingEventCount =
          allEvents.where((event) {
            return event.startTime.isAfter(now) &&
                event.startTime.isBefore(sevenDaysLater);
          }).length;

      // 获取过期活动数量
      final expiredEventCount =
          allEvents.where((event) {
            return event.startTime.isBefore(now);
          }).length;

      return [
        StatItemData(
          id: 'event_count',
          label: 'calendar_activityCount'.tr,
          value: '$eventCount',
          highlight: false,
        ),
        StatItemData(
          id: 'week_events',
          label: 'calendar_sevenDaysActivity'.tr,
          value: '$upcomingEventCount',
          highlight: upcomingEventCount > 0,
          color: Colors.orange,
        ),
        StatItemData(
          id: 'expired_events',
          label: 'calendar_expiredActivity'.tr,
          value: '$expiredEventCount',
          highlight: expiredEventCount > 0,
          color: Colors.red,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
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
        pluginId: 'calendar',
        pluginName: 'calendar_name'.tr,
        pluginIcon: Icons.calendar_month,
        pluginDefaultColor: const Color.fromARGB(255, 211, 91, 91),
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
