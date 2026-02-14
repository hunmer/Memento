/// 日历相册插件 - 本周相册小组件注册
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:provider/provider.dart';
import 'utils.dart';

/// 注册 4x1 宽屏卡片 - 本周相册（占满宽度）
void registerWeeklyAlbumWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_album_weekly',
      pluginId: 'calendar_album',
      name: 'calendar_album_weekly_name'.tr,
      description: 'calendar_album_weekly_description'.tr,
      icon: Icons.photo_library_rounded,
      color: pluginColor,
      defaultSize: HomeWidgetSize.wide2,
      supportedSizes: [HomeWidgetSize.wide, HomeWidgetSize.wide2],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildWeeklyAlbumWidget(context, config),
    ),
  );
}

/// 构建本周相册小组件
Widget _buildWeeklyAlbumWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  try {
    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'calendar_entry_added',
            'calendar_entry_updated',
            'calendar_entry_deleted',
            'calendar_tag_added',
            'calendar_tag_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildWeeklyAlbumWidgetContent(context),
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 构建本周相册小组件内容（获取最新数据）
Widget _buildWeeklyAlbumWidgetContent(BuildContext context) {
  final plugin =
      PluginManager.instance.getPlugin('calendar_album')
          as CalendarAlbumPlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(context, 'Plugin not found');
  }

  final controller = plugin.calendarController;
  if (controller == null) {
    return HomeWidget.buildErrorWidget(context, 'Controller not found');
  }

  final now = DateTime.now();
  final weekDays = getCurrentWeekDays(now);

  // 构建每天的日记数据
  final Map<DateTime, List<CalendarEntry>> weekEntries = {};
  for (final date in weekDays) {
    weekEntries[date] = controller.getEntriesForDate(date);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 七天卡片
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                weekDays.map((date) {
                  final entries = weekEntries[date] ?? [];
                  final firstEntry = entries.isNotEmpty ? entries.first : null;
                  return _buildDayPhotoCard(context, date, firstEntry, plugin);
                }).toList(),
          ),
        ),
      ],
    ),
  );
}

/// 构建单日照片卡片
Widget _buildDayPhotoCard(
  BuildContext context,
  DateTime date,
  CalendarEntry? entry,
  CalendarAlbumPlugin plugin,
) {
  final today = DateTime.now();
  final isToday = isSameDay(date, today);
  final weekdayText = formatWeekday(date);
  final dayText = formatDay(date);

  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday ? pluginColor.withAlpha(25) : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: pluginColor, width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDateAlbum(context, date, entry, plugin),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 星期几
                Text(
                  weekdayText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? pluginColor : Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                // 图片预览区域
                Expanded(child: _buildPhotoPreview(context, entry)),
                const SizedBox(height: 2),
                // 日期数字
                Text(
                  dayText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? pluginColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 构建照片预览
Widget _buildPhotoPreview(BuildContext context, CalendarEntry? entry) {
  if (entry == null) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 20,
          color: Colors.grey.withAlpha(102),
        ),
      ),
    );
  }

  // 获取第一张图片（优先使用缩略图）
  final imageUrl =
      entry.thumbUrls.isNotEmpty
          ? entry.thumbUrls.first
          : (entry.imageUrls.isNotEmpty ? entry.imageUrls.first : null);

  if (imageUrl == null) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          Icons.notes_outlined,
          size: 20,
          color: Colors.grey.withAlpha(102),
        ),
      ),
    );
  }

  return FutureBuilder<String>(
    future: ImageUtils.getAbsolutePath(imageUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      final imagePath = snapshot.data;
      if (imagePath == null || imagePath.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 20,
              color: Colors.grey.withAlpha(102),
            ),
          ),
        );
      }

      final file = File(imagePath);
      if (!file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 20,
              color: Colors.grey.withAlpha(102),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 20,
                  color: Colors.grey.withAlpha(102),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// 打开日期相册（如果有日记则打开详情页，否则打开该日期的日记列表）
Future<void> _openDateAlbum(
  BuildContext context,
  DateTime date,
  CalendarEntry? entry,
  CalendarAlbumPlugin plugin,
) async {
  if (entry != null) {
    // 有日记，打开日记详情
    NavigationHelper.push(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: plugin.calendarController!),
          ChangeNotifierProvider.value(value: plugin.tagController!),
        ],
        child: EntryDetailScreen(entry: entry),
      ),
    );
  } else {
    // 没有日记，打开日历视图并选择该日期
    plugin.calendarController?.selectDate(date);
    NavigationHelper.pushNamed(context, '/calendar_album');
  }
}
