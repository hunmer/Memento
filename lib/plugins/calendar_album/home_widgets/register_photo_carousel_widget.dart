/// 日历相册插件 - 图片轮播小组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'data.dart';
import 'utils.dart';
import 'widgets/photo_carousel_widget.dart';

/// 注册 2x2, 4x2, 4x3 滑动滚动图片小组件
void registerPhotoCarouselWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_album_photo_carousel',
      pluginId: 'calendar_album',
      name: 'calendar_album_photo_carousel_name'.tr,
      description: 'calendar_album_photo_carousel_description'.tr,
      icon: Icons.photo_camera_rounded,
      color: pluginColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [
        HomeWidgetSize.large, // 2x2
        HomeWidgetSize.wide2, // 4x2
        HomeWidgetSize.wide3, // 4x3
      ],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildPhotoCarouselWidget(context, config),
    ),
  );
}

/// 构建滑动滚动图片小组件
Widget _buildPhotoCarouselWidget(
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
          child: _buildPhotoCarouselWidgetContent(context),
        );
      },
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 构建滑动滚动图片小组件内容（获取最新数据）
Widget _buildPhotoCarouselWidgetContent(BuildContext context) {
  final plugin = PluginManager.instance.getPlugin('calendar_album')
      as CalendarAlbumPlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(context, 'Plugin not found');
  }

  final controller = plugin.calendarController;
  if (controller == null) {
    return HomeWidget.buildErrorWidget(context, 'Controller not found');
  }

  // 获取最近30天的图片
  final photos = _getRecentPhotos(controller, days: 30);

  if (photos.isEmpty) {
    return _buildEmptyPhotoWidget(context);
  }

  return PhotoCarouselWidget(
    photos: photos,
    plugin: plugin,
  );
}

/// 获取最近指定天数的图片列表
List<PhotoItem> _getRecentPhotos(
  CalendarController controller, {
  int days = 30,
}) {
  final photos = <PhotoItem>[];
  final now = DateTime.now();

  // 遍历最近N天的每一天
  for (int i = 0; i < days; i++) {
    final date = now.subtract(Duration(days: i));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final entries = controller.getEntriesForDate(normalizedDate);

    for (final entry in entries) {
      // 优先使用缩略图，其次原图
      if (entry.thumbUrls.isNotEmpty) {
        for (final imageUrl in entry.thumbUrls) {
          photos.add(
            PhotoItem(
              imageUrl: imageUrl,
              entry: entry,
              date: normalizedDate,
            ),
          );
        }
      } else if (entry.imageUrls.isNotEmpty) {
        for (final imageUrl in entry.imageUrls) {
          photos.add(
            PhotoItem(
              imageUrl: imageUrl,
              entry: entry,
              date: normalizedDate,
            ),
          );
        }
      }

      // 也从 Markdown 内容中提取图片
      final markdownImages = entry.extractImagesFromMarkdown();
      for (final imageUrl in markdownImages) {
        photos.add(
          PhotoItem(imageUrl: imageUrl, entry: entry, date: normalizedDate),
        );
      }
    }
  }

  return photos;
}

/// 构建空照片状态
Widget _buildEmptyPhotoWidget(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.withAlpha(13),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.grey.withAlpha(102),
          ),
          const SizedBox(height: 12),
          Text(
            'calendar_album_no_photos'.tr,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
