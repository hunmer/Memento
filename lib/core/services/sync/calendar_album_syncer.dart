import 'package:flutter/material.dart';
import '../../../plugins/calendar_album/calendar_album_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 日记相册插件同步器
class CalendarAlbumSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('calendar_album', () async {
      final plugin = PluginManager.instance.getPlugin('calendar_album') as CalendarAlbumPlugin?;
      if (plugin == null) return;

      final totalPhotos = plugin.getTotalPhotosCount();
      final todayPhotos = plugin.getTodayPhotosCount();
      final tagsCount = plugin.getTagsCount();

      await updateWidget(
        pluginId: 'calendar_album',
        pluginName: '相册',
        iconCodePoint: Icons.photo_album.codePoint,
        colorValue: Colors.lime.shade700.value,
        stats: [
          WidgetStatItem(
            id: 'total_photos',
            label: '总照片',
            value: '$totalPhotos',
            highlight: totalPhotos > 0,
            colorValue: totalPhotos > 0 ? Colors.lime.value : null,
          ),
          WidgetStatItem(
            id: 'today_photos',
            label: '今日新增',
            value: '$todayPhotos',
            highlight: todayPhotos > 0,
            colorValue: todayPhotos > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'tags',
            label: '标签数',
            value: '$tagsCount',
          ),
        ],
      );
    });
  }

  /// 同步每周相册小组件
  Future<void> syncCalendarAlbumWeeklyWidget() async {
    await syncSafely('calendar_album_weekly', () async {
      // 每周相册小组件使用自定义同步逻辑，不需要通过 updateWidget
      debugPrint('每周相册小组件数据已更新');
    });
  }
}
