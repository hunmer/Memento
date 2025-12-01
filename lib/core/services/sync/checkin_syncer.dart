import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memento_widgets/memento_widgets.dart';
import '../../../plugins/checkin/checkin_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import '../system_widget_service.dart';

/// 签到插件同步器
class CheckinSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for checkin');
      return;
    }

    await syncSafely('checkin', () async {
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) return;

      final todayCount = plugin.getTodayCheckins();
      final totalItems = plugin.checkinItems.length;
      final totalCheckins = plugin.getTotalCheckins();

      int maxConsecutiveDays = 0;
      for (final item in plugin.checkinItems) {
        final consecutive = item.getConsecutiveDays();
        if (consecutive > maxConsecutiveDays) {
          maxConsecutiveDays = consecutive;
        }
      }

      await updateWidget(
        pluginId: 'checkin',
        pluginName: '签到',
        iconCodePoint: Icons.check_circle.codePoint,
        colorValue: Colors.teal.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日完成',
            value: '$todayCount/$totalItems',
            highlight: todayCount == totalItems && totalItems > 0,
            colorValue: todayCount == totalItems && totalItems > 0
                ? Colors.green.value
                : null,
          ),
          WidgetStatItem(
            id: 'total',
            label: '总签到数',
            value: '$totalCheckins',
          ),
          WidgetStatItem(
            id: 'streak',
            label: '最长连续',
            value: '$maxConsecutiveDays天',
            highlight: maxConsecutiveDays >= 7,
            colorValue: maxConsecutiveDays >= 7 ? Colors.amber.value : null,
          ),
        ],
      );
    });
  }

  /// 同步自定义签到项小组件
  Future<void> syncCheckinItemWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) {
        debugPrint('Checkin plugin not found, skipping checkin_item widget sync');
        return;
      }

      final items = plugin.checkinItems.map((item) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<String> weekChecks = [];

        final mondayOffset = today.weekday - 1;
        final monday = today.subtract(Duration(days: mondayOffset));

        for (int i = 0; i < 7; i++) {
          final date = monday.add(Duration(days: i));
          final hasCheckin = item.getDateRecords(date).isNotEmpty;
          weekChecks.add(hasCheckin ? '1' : '0');
        }

        final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
        final List<int> monthChecks = [];

        for (int day = 1; day <= lastDayOfMonth.day; day++) {
          final date = DateTime(today.year, today.month, day);
          final hasCheckin = item.getDateRecords(date).isNotEmpty;
          if (hasCheckin) {
            monthChecks.add(day);
          }
        }

        return {
          'id': item.id,
          'name': item.name,
          'weekChecks': weekChecks.join(','),
          'monthChecks': monthChecks.join(','),
        };
      }).toList();

      final data = {'items': items};
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('checkin_item_widget_data', jsonString);

      await SystemWidgetService.instance.updateWidget('checkin_item');
      await SystemWidgetService.instance.updateWidget('checkin_month');

      debugPrint('Synced checkin widgets (item & month) with ${items.length} items');
    } catch (e) {
      debugPrint('Failed to sync checkin_item widget: $e');
    }
  }

  /// 同步打卡周视图小组件
  Future<void> syncCheckinWeeklyWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) {
        debugPrint('Checkin plugin not found, skipping checkin_weekly widget sync');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mondayOffset = today.weekday - 1;
      final monday = today.subtract(Duration(days: mondayOffset));

      final items = plugin.checkinItems.map((item) {
        String colorName = 'gray';
        if (item.color != null) {
          final colorValue = item.color.value;
          colorName = _getColorNameFromValue(colorValue);
        }

        return {
          'id': item.id,
          'name': item.name,
          'color': colorName,
        };
      }).toList();

      final Map<String, Map<String, int>> dailyCheckins = {};

      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final dayData = <String, int>{};
        for (final item in plugin.checkinItems) {
          final records = item.getDateRecords(date);
          dayData[item.id] = records.length;
        }

        dailyCheckins[dateStr] = dayData;
      }

      final data = {
        'items': items,
        'dailyCheckins': dailyCheckins,
      };
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('checkin_weekly_list_widget_data', jsonString);

      await SystemWidgetService.instance.updateWidget('checkin_weekly_list');

      debugPrint('Synced checkin_weekly_list widget with ${items.length} items');
    } catch (e) {
      debugPrint('Failed to sync checkin_weekly widget: $e');
    }
  }

  /// 根据颜色值获取颜色名称
  String _getColorNameFromValue(int colorValue) {
    final r = (colorValue >> 16) & 0xFF;
    final g = (colorValue >> 8) & 0xFF;
    final b = colorValue & 0xFF;

    if (r > 200 && g < 150 && b < 150) return 'red';
    if (r > 200 && g > 150 && g < 200 && b < 100) return 'orange';
    if (r > 200 && g > 200 && b < 100) return 'yellow';
    if (r < 150 && g > 180 && b < 150) return 'green';
    if (r < 150 && g > 150 && b > 200) return 'blue';
    if (r > 150 && g < 150 && b > 200) return 'purple';
    if (r > 200 && g < 150 && b > 150) return 'pink';
    if (r < 150 && g > 180 && b > 180) return 'teal';
    if (r > 100 && r < 150 && g > 100 && g < 150 && b > 200) return 'indigo';

    return 'gray';
  }
}
