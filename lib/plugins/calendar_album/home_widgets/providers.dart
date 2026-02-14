/// 日历相册插件主页小组件数据提供者

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../calendar_album_plugin.dart';
import 'utils.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('calendar_album')
        as CalendarAlbumPlugin?;
    if (plugin == null) return [];

    final todayCount = plugin.calendarController?.getTodayEntriesCount();
    final sevenDayCount = plugin.calendarController?.getLast7DaysEntriesCount();
    final allEntriesCount = plugin.calendarController!.getAllEntriesCount();
    final tagCount = plugin.tagController?.tags.length;

    return [
      StatItemData(
        id: 'today_diary',
        label: 'calendar_album_today_diary'.tr,
        value: '$todayCount',
        highlight: todayCount! > 0,
        color: pluginColor,
      ),
      StatItemData(
        id: 'seven_day_diary',
        label: 'calendar_album_seven_days_diary'.tr,
        value: '$sevenDayCount',
        highlight: false,
      ),
      StatItemData(
        id: 'all_diaries',
        label: 'calendar_album_all_diaries'.tr,
        value: '$allEntriesCount',
        highlight: false,
      ),
      StatItemData(
        id: 'tag_count',
        label: 'calendar_album_tag_count'.tr,
        value: '$tagCount',
        highlight: false,
      ),
    ];
  } catch (e) {
    return [];
  }
}
