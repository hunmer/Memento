import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import 'screens/main_screen.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';
import 'controls/prompt_controller.dart';
import 'models/calendar_entry.dart';
import 'l10n/calendar_album_localizations.dart';

/// 日历相册插件主视图
class CalendarAlbumMainView extends StatefulWidget {
  const CalendarAlbumMainView({super.key});

  @override
  State<CalendarAlbumMainView> createState() => _CalendarAlbumMainViewState();
}

class _CalendarAlbumMainViewState extends State<CalendarAlbumMainView> {
  late CalendarAlbumPlugin _plugin;
  @override
  void initState() {
    super.initState();
    _plugin = CalendarAlbumPlugin.instance;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _plugin.calendarController),
        ChangeNotifierProvider.value(value: _plugin.tagController),
      ],
      child: const MainScreen(),
    );
  }
}

class CalendarAlbumPlugin extends BasePlugin with JSBridgePlugin {
  static CalendarAlbumPlugin? _instance;
  static CalendarAlbumPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('calendar_album')
              as CalendarAlbumPlugin?;
      if (_instance == null) {
        throw StateError('CalendarAlbumPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late final CalendarController calendarController;
  late final TagController tagController;
  late final CalendarAlbumPromptController _promptController;

  @override
  String get id => 'calendar_album';

  @override
  Color get color => const Color.fromARGB(255, 245, 210, 52);

  @override
  IconData get icon => Icons.notes_rounded;

  @override
  Future<void> initialize() async {
    calendarController = CalendarController();
    tagController = TagController(onTagsChanged: () {});

    // 初始化Prompt控制器
    _promptController = CalendarAlbumPromptController(this);
    _promptController.initialize();

    await initializeDefaultData();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return CalendarAlbumLocalizations.of(context).name;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return CalendarAlbumMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                CalendarAlbumLocalizations.of(context).name,

                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 今日日记和七日日记
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).todayDiary,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getTodayEntriesCount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 七日日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).sevenDayDiary,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getLast7DaysEntriesCount()} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 所有日记和标签
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 所有日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).allDiaries,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getAllEntriesCount()} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 标签数量
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).tagCount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${tagController.tags.length} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 测试API（同步）
      'testSync': _jsTestSync,

      // 日记相关
      'getEntries': _jsGetEntries,
      'getEntriesForDate': _jsGetEntriesForDate,
      'addEntry': _jsAddEntry,
      'updateEntry': _jsUpdateEntry,
      'deleteEntry': _jsDeleteEntry,
      'getEntryById': _jsGetEntryById,

      // 标签相关
      'getTags': _jsGetTags,
      'getEntriesByTag': _jsGetEntriesByTag,
      'getEntriesByTags': _jsGetEntriesByTags,

      // 照片相关
      'getPhotos': _jsGetPhotos,
      'getPhotosByDateRange': _jsGetPhotosByDateRange,

      // 统计相关
      'getStatistics': _jsGetStatistics,
    };
  }

  // ==================== JS API 实现 ====================

  /// 同步测试 API
  String _jsTestSync() {
    return jsonEncode({
      'status': 'ok',
      'message': '日历相册插件同步测试成功！',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 获取所有日记条目
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntries() async {
    final allEntries = <CalendarEntry>[];
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });
    // 按创建时间倒序排序
    allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jsonEncode(allEntries.map((e) => e.toJson()).toList());
  }

  /// 获取指定日期的日记条目
  /// @param dateStr - 日期字符串 (YYYY-MM-DD)
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesForDate(String dateStr) async {
    try {
      final date = DateTime.parse(dateStr);
      final entries = calendarController.getEntriesForDate(date);
      return jsonEncode(entries.map((e) => e.toJson()).toList());
    } catch (e) {
      return jsonEncode({
        'error': '日期格式错误: $dateStr',
        'message': '请使用 YYYY-MM-DD 格式',
      });
    }
  }

  /// 添加日记条目
  /// @param title - 标题
  /// @param content - 内容
  /// @param dateStr - 日期 (可选, 默认今天)
  /// @param tagsStr - 标签 (可选, 逗号分隔)
  /// @param location - 位置 (可选)
  /// @param mood - 心情 (可选)
  /// @param weather - 天气 (可选)
  /// @param imageUrlsStr - 图片URL列表 (可选, 逗号分隔)
  Future<String> _jsAddEntry(
    String title,
    String content, [
    String? dateStr,
    String? tagsStr,
    String? location,
    String? mood,
    String? weather,
    String? imageUrlsStr,
  ]) async {
    try {
      final createdAt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      final tags = tagsStr?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [];
      final imageUrls = imageUrlsStr?.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList() ?? [];

      final entry = CalendarEntry.create(
        title: title,
        content: content,
        createdAt: createdAt,
        tags: tags,
        location: location,
        mood: mood,
        weather: weather,
        imageUrls: imageUrls,
      );

      await calendarController.addEntry(entry);
      return jsonEncode(entry.toJson());
    } catch (e) {
      return jsonEncode({
        'error': '添加日记失败',
        'message': e.toString(),
      });
    }
  }

  /// 更新日记条目
  /// @param entryId - 日记ID
  /// @param title - 新标题 (可选)
  /// @param content - 新内容 (可选)
  /// @param tagsStr - 新标签 (可选, 逗号分隔)
  /// @param location - 新位置 (可选)
  /// @param mood - 新心情 (可选)
  /// @param weather - 新天气 (可选)
  /// @param imageUrlsStr - 新图片URL列表 (可选, 逗号分隔)
  Future<String> _jsUpdateEntry(
    String entryId, [
    String? title,
    String? content,
    String? tagsStr,
    String? location,
    String? mood,
    String? weather,
    String? imageUrlsStr,
  ]) async {
    try {
      final entry = calendarController.getEntryById(entryId);
      if (entry == null) {
        return jsonEncode({
          'error': '日记不存在',
          'entryId': entryId,
        });
      }

      final tags =
          tagsStr
              ?.split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
      final imageUrls =
          imageUrlsStr
              ?.split(',')
              .map((u) => u.trim())
              .where((u) => u.isNotEmpty)
              .toList();

      final updatedEntry = entry.copyWith(
        title: title,
        content: content,
        tags: tags,
        location: location,
        mood: mood,
        weather: weather,
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      await calendarController.updateEntry(updatedEntry);
      return jsonEncode(updatedEntry.toJson());
    } catch (e) {
      return jsonEncode({
        'error': '更新日记失败',
        'message': e.toString(),
      });
    }
  }

  /// 删除日记条目
  /// @param entryId - 日记ID
  Future<String> _jsDeleteEntry(String entryId) async {
    try {
      final entry = calendarController.getEntryById(entryId);
      if (entry == null) {
        return jsonEncode({
          'success': false,
          'error': '日记不存在',
          'entryId': entryId,
        });
      }

      await calendarController.deleteEntry(entry);
      return jsonEncode({
        'success': true,
        'entryId': entryId,
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': '删除日记失败',
        'message': e.toString(),
      });
    }
  }

  /// 根据ID获取日记条目
  /// @param entryId - 日记ID
  Future<String> _jsGetEntryById(String entryId) async {
    final entry = calendarController.getEntryById(entryId);
    if (entry == null) {
      return jsonEncode({
        'error': '日记不存在',
        'entryId': entryId,
      });
    }
    return jsonEncode(entry.toJson());
  }

  /// 获取所有标签
  /// 返回: List<String> (JSON数组)
  Future<String> _jsGetTags() async {
    final tags = tagController.tags;
    return jsonEncode(tags);
  }

  /// 根据单个标签获取日记
  /// @param tag - 标签名称
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesByTag(String tag) async {
    final entries = calendarController.getEntriesByTag(tag);
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// 根据多个标签获取日记 (AND逻辑)
  /// @param tagsStr - 标签列表 (逗号分隔)
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesByTags(String tagsStr) async {
    final tags = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (tags.isEmpty) {
      return jsonEncode([]);
    }
    final entries = calendarController.getEntriesByTags(tags);
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// 获取所有照片URL
  /// 返回: List<String> (JSON数组)
  Future<String> _jsGetPhotos() async {
    final photos = calendarController.getAllImages();
    return jsonEncode(photos);
  }

  /// 根据日期范围获取照片
  /// @param startDateStr - 开始日期 (YYYY-MM-DD)
  /// @param endDateStr - 结束日期 (YYYY-MM-DD)
  /// 返回: List<{date: String, imageUrl: String, entryId: String}> (JSON数组)
  Future<String> _jsGetPhotosByDateRange(String startDateStr, String endDateStr) async {
    try {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);

      final List<Map<String, dynamic>> photos = [];

      calendarController.entries.forEach((date, entries) {
        if ((date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
            (date.isBefore(endDate) || date.isAtSameMomentAs(endDate))) {
          for (var entry in entries) {
            final allImages = <String>[...entry.imageUrls, ...entry.extractImagesFromMarkdown()];
            for (var imageUrl in allImages) {
              photos.add({
                'date': date.toIso8601String(),
                'imageUrl': imageUrl,
                'entryId': entry.id,
                'entryTitle': entry.title,
              });
            }
          }
        }
      });

      return jsonEncode(photos);
    } catch (e) {
      return jsonEncode({
        'error': '日期格式错误',
        'message': '请使用 YYYY-MM-DD 格式',
      });
    }
  }

  /// 获取统计信息
  /// 返回: {todayCount, last7DaysCount, totalCount, tagCount, photoCount}
  Future<String> _jsGetStatistics() async {
    final stats = {
      'todayCount': calendarController.getTodayEntriesCount(),
      'last7DaysCount': calendarController.getLast7DaysEntriesCount(),
      'totalCount': calendarController.getAllEntriesCount(),
      'tagCount': tagController.tags.length,
      'photoCount': calendarController.getAllImages().length,
    };
    return jsonEncode(stats);
  }
}
