import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:Memento/utils/image_utils.dart';
import 'dart:io';
import 'dart:async';
import 'calendar_album_plugin.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

/// 日历相册插件的主页小组件注册
class CalendarAlbumHomeWidgets {
  static const Color _pluginColor = Color.fromARGB(255, 245, 210, 52);

  /// 注册所有日历相册插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'calendar_album_icon',
        pluginId: 'calendar_album',
        name: 'calendar_album_widget_name'.tr,
        description: 'calendar_album_widget_description'.tr,
        icon: Icons.notes_rounded,
        color: _pluginColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.notes_rounded,
              color: _pluginColor,
              name: 'calendar_album_widget_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'calendar_album_overview',
        pluginId: 'calendar_album',
        name: 'calendar_album_overview_name'.tr,
        description: 'calendar_album_overview_description'.tr,
        icon: Icons.calendar_today,
        color: _pluginColor,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 4x1 宽屏卡片 - 本周相册（占满宽度）
    registry.register(
      HomeWidget(
        id: 'calendar_album_weekly',
        pluginId: 'calendar_album',
        name: 'calendar_album_weekly_name'.tr,
        description: 'calendar_album_weekly_description'.tr,
        icon: Icons.photo_library_rounded,
        color: _pluginColor,
        defaultSize: HomeWidgetSize.wide2,
        supportedSizes: [HomeWidgetSize.wide, HomeWidgetSize.wide2],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildWeeklyAlbumWidget(context, config),
      ),
    );

    // 2x2, 4x2, 4x3 滑动滚动图片小组件
    registry.register(
      HomeWidget(
        id: 'calendar_album_photo_carousel',
        pluginId: 'calendar_album',
        name: 'calendar_album_photo_carousel_name'.tr,
        description: 'calendar_album_photo_carousel_description'.tr,
        icon: Icons.photo_camera_rounded,
        color: _pluginColor,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [
          HomeWidgetSize.large, // 2x2
          HomeWidgetSize.wide2, // 4x2
          HomeWidgetSize.wide3, // 4x3
        ],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => _buildPhotoCarouselWidget(context, config),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar_album')
              as CalendarAlbumPlugin?;
      if (plugin == null) return [];

      final todayCount = plugin.calendarController?.getTodayEntriesCount();
      final sevenDayCount =
          plugin.calendarController?.getLast7DaysEntriesCount();
      final allEntriesCount = plugin.calendarController!.getAllEntriesCount();
      final tagCount = plugin.tagController?.tags.length;

      return [
        StatItemData(
          id: 'today_diary',
          label: 'calendar_album_today_diary'.tr,
          value: '$todayCount',
          highlight: todayCount! > 0,
          color: _pluginColor,
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
        pluginId: 'calendar_album',
        pluginName: 'calendar_album_name'.tr,
        pluginIcon: Icons.notes_rounded,
        pluginDefaultColor: _pluginColor,
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

  /// 构建本周相册小组件
  static Widget _buildWeeklyAlbumWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar_album')
              as CalendarAlbumPlugin?;
      if (plugin == null) return _buildErrorWidget(context, 'Plugin not found');

      final controller = plugin.calendarController;
      if (controller == null) {
        return _buildErrorWidget(context, 'Controller not found');
      }

      final now = DateTime.now();
      final weekDays = _getCurrentWeekDays(now);

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
                      final firstEntry =
                          entries.isNotEmpty ? entries.first : null;
                      return _buildDayPhotoCard(
                        context,
                        date,
                        firstEntry,
                        plugin,
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 获取当前周的周一到周日日期
  static List<DateTime> _getCurrentWeekDays(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // Monday = 1, Sunday = 7
    final weekday = normalizedDate.weekday;
    // 计算周一
    final monday = normalizedDate.subtract(Duration(days: weekday - 1));
    // 生成周一到周日的日期列表
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// 构建单日照片卡片
  static Widget _buildDayPhotoCard(
    BuildContext context,
    DateTime date,
    CalendarEntry? entry,
    CalendarAlbumPlugin plugin,
  ) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final weekdayFormat = DateFormat.E('zh');
    final dayFormat = DateFormat.d();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color:
              isToday ? _pluginColor.withAlpha(25) : Colors.grey.withAlpha(13),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: _pluginColor, width: 1.5) : null,
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
                    weekdayFormat.format(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isToday ? _pluginColor : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 图片预览区域
                  Expanded(child: _buildPhotoPreview(context, entry)),
                  const SizedBox(height: 2),
                  // 日期数字
                  Text(
                    dayFormat.format(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isToday ? _pluginColor : Colors.black87,
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
  static Widget _buildPhotoPreview(BuildContext context, CalendarEntry? entry) {
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
  static Future<void> _openDateAlbum(
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

  /// 构建滑动滚动图片小组件
  static Widget _buildPhotoCarouselWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar_album')
              as CalendarAlbumPlugin?;
      if (plugin == null) return _buildErrorWidget(context, 'Plugin not found');

      final controller = plugin.calendarController;
      if (controller == null) {
        return _buildErrorWidget(context, 'Controller not found');
      }

      // 获取最近30天的图片
      final photos = _getRecentPhotos(controller, days: 30);

      if (photos.isEmpty) {
        return _buildEmptyPhotoWidget(context);
      }

      return _PhotoCarouselWidget(
        photos: photos,
        plugin: plugin,
        pluginColor: _pluginColor,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 获取最近指定天数的图片列表
  static List<_PhotoItem> _getRecentPhotos(
    CalendarController controller, {
    int days = 30,
  }) {
    final photos = <_PhotoItem>[];
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
              _PhotoItem(
                imageUrl: imageUrl,
                entry: entry,
                date: normalizedDate,
              ),
            );
          }
        } else if (entry.imageUrls.isNotEmpty) {
          for (final imageUrl in entry.imageUrls) {
            photos.add(
              _PhotoItem(
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
            _PhotoItem(imageUrl: imageUrl, entry: entry, date: normalizedDate),
          );
        }
      }
    }

    return photos;
  }

  /// 构建空照片状态
  static Widget _buildEmptyPhotoWidget(BuildContext context) {
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片项数据类
class _PhotoItem {
  final String imageUrl;
  final CalendarEntry entry;
  final DateTime date;

  _PhotoItem({required this.imageUrl, required this.entry, required this.date});
}

/// 滑动滚动图片小组件（StatefulWidget 以管理控制器）
class _PhotoCarouselWidget extends StatefulWidget {
  final List<_PhotoItem> photos;
  final CalendarAlbumPlugin plugin;
  final Color pluginColor;

  const _PhotoCarouselWidget({
    required this.photos,
    required this.plugin,
    required this.pluginColor,
  });

  @override
  State<_PhotoCarouselWidget> createState() => _PhotoCarouselWidgetState();
}

class _PhotoCarouselWidgetState extends State<_PhotoCarouselWidget>
    with SingleTickerProviderStateMixin {
  late InfiniteScrollController _controller;
  late Timer _autoScrollTimer;
  final Map<String, File> _loadedImages = {};

  @override
  void initState() {
    super.initState();
    _controller = InfiniteScrollController();
    // 预加载前几张图片
    _preloadImages();
    // 启动自动滚动（5秒）
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _controller.dispose();
    _loadedImages.clear();
    super.dispose();
  }

  /// 启动自动滚动
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _controller.hasClients) {
        _controller.nextItem(duration: const Duration(milliseconds: 500));
      }
    });
  }

  /// 预加载图片
  Future<void> _preloadImages() async {
    final preloadCount = widget.photos.length < 10 ? widget.photos.length : 10;
    for (int i = 0; i < preloadCount; i++) {
      _loadImageAsync(widget.photos[i].imageUrl);
    }
  }

  /// 异步加载图片
  Future<void> _loadImageAsync(String imageUrl) async {
    if (_loadedImages.containsKey(imageUrl)) return;

    try {
      final path = await ImageUtils.getAbsolutePath(imageUrl);
      if (path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          if (mounted) {
            setState(() {
              _loadedImages[imageUrl] = file;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('预加载图片失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: InfiniteCarousel.builder(
        itemCount: widget.photos.length,
        itemExtent: 136, // 120图片宽度 + 16左右间距(每边8)
        center: true,
        anchor: 0.15,
        velocityFactor: 0.2,
        controller: _controller,
        axisDirection: Axis.horizontal,
        loop: true,
        itemBuilder: (context, itemIndex, realIndex) {
          final photo = widget.photos[itemIndex];
          return _buildCarouselPhotoItem(photo, itemIndex);
        },
      ),
    );
  }

  /// 构建轮播图片项
  Widget _buildCarouselPhotoItem(_PhotoItem photo, int index) {
    final imageFile = _loadedImages[photo.imageUrl];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _openPhotoDetail(photo),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.expand(
            child: imageFile != null
                ? Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  )
                : Stack(
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      FutureBuilder<String>(
                        future: ImageUtils.getAbsolutePath(photo.imageUrl),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.data != null &&
                              snapshot.data!.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              final path = snapshot.data!;
                              final file = File(path);
                              if (file.existsSync() && mounted) {
                                setState(() {
                                  _loadedImages[photo.imageUrl] = file;
                                });
                              }
                            });
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 打开图片对应的日记详情
  void _openPhotoDetail(_PhotoItem photo) {
    NavigationHelper.push(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: widget.plugin.calendarController!,
          ),
          ChangeNotifierProvider.value(value: widget.plugin.tagController!),
        ],
        child: EntryDetailScreen(entry: photo.entry),
      ),
    );
  }
}
