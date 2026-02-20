/// 日历插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:get/get.dart';
import '../calendar_plugin.dart';
import '../models/event.dart';

// 导出 CommandWidgetsProvider
export 'providers/command_widgets_provider.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
    if (plugin == null) return [];

    final allEvents = plugin.controller.getAllEvents();
    final eventCount = allEvents.length;

    // 获取7天内的活动数量
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    final upcomingEventCount = allEvents.where((event) {
      return event.startTime.isAfter(now) && event.startTime.isBefore(sevenDaysLater);
    }).length;

    // 获取过期活动数量
    final expiredEventCount = allEvents.where((event) {
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

/// 获取未来7天的事件列表
List<CalendarEvent> getUpcomingEvents(int limit) {
  try {
    final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
    if (plugin != null) {
      final controller = plugin.controller;
      final allEvents = controller.getAllEvents();
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));

      // 获取未来7天内的未完成事件
      final upcomingEvents = allEvents.where((event) {
        return event.startTime.isAfter(now) &&
            event.startTime.isBefore(sevenDaysLater) &&
            event.completedTime == null;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      return upcomingEvents.take(limit).toList();
    }
  } catch (e) {
    debugPrint('[CalendarHomeWidgets] 获取事件列表失败: $e');
  }
  return [];
}
