// ignore_for_file: unintended_html_in_doc_comment

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

  /// 获取所有日记条目
  /// @param params - 参数对象（无参数）
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntries(Map<String, dynamic> params) async {
    final allEntries = <CalendarEntry>[];
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });
    // 按创建时间倒序排序
    allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jsonEncode(allEntries.map((e) => e.toJson()).toList());
  }

  /// 获取指定日期的日记条目
  /// @param params.dateStr - 日期字符串 (YYYY-MM-DD)
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesForDate(Map<String, dynamic> params) async {
    final String? dateStr = params['dateStr'];
    if (dateStr == null || dateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: dateStr'});
    }

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
  /// @param params.title - 标题
  /// @param params.content - 内容
  /// @param params.dateStr - 日期 (可选, 默认今天)
  /// @param params.tags - 标签数组 (可选)
  /// @param params.location - 位置 (可选)
  /// @param params.mood - 心情 (可选)
  /// @param params.weather - 天气 (可选)
  /// @param params.imageUrls - 图片URL数组 (可选)
  Future<String> _jsAddEntry(Map<String, dynamic> params) async {
    final String? title = params['title'];
    final String? content = params['content'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }
    if (content == null) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    try {
      final String? dateStr = params['dateStr'];
      final List<String> tags = params['tags'] != null ? List<String>.from(params['tags']) : [];
      final String? location = params['location'];
      final String? mood = params['mood'];
      final String? weather = params['weather'];
      final List<String> imageUrls = params['imageUrls'] != null ? List<String>.from(params['imageUrls']) : [];

      final createdAt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

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
  /// @param params.entryId - 日记ID
  /// @param params.title - 新标题 (可选)
  /// @param params.content - 新内容 (可选)
  /// @param params.tags - 新标签数组 (可选)
  /// @param params.location - 新位置 (可选)
  /// @param params.mood - 新心情 (可选)
  /// @param params.weather - 新天气 (可选)
  /// @param params.imageUrls - 新图片URL数组 (可选)
  Future<String> _jsUpdateEntry(Map<String, dynamic> params) async {
    final String? entryId = params['entryId'];
    if (entryId == null || entryId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: entryId'});
    }

    try {
      final entry = calendarController.getEntryById(entryId);
      if (entry == null) {
        return jsonEncode({
          'error': '日记不存在',
          'entryId': entryId,
        });
      }

      final String? title = params['title'];
      final String? content = params['content'];
      final List<String>? tags = params['tags'] != null ? List<String>.from(params['tags']) : null;
      final String? location = params['location'];
      final String? mood = params['mood'];
      final String? weather = params['weather'];
      final List<String>? imageUrls = params['imageUrls'] != null ? List<String>.from(params['imageUrls']) : null;

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
  /// @param params.entryId - 日记ID
  Future<String> _jsDeleteEntry(Map<String, dynamic> params) async {
    final String? entryId = params['entryId'];
    if (entryId == null || entryId.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': '缺少必需参数: entryId',
      });
    }

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
  /// @param params.entryId - 日记ID
  Future<String> _jsGetEntryById(Map<String, dynamic> params) async {
    final String? entryId = params['entryId'];
    if (entryId == null || entryId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: entryId'});
    }

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
  /// @param params - 参数对象（无参数）
  /// 返回: List<String> (JSON数组)
  Future<String> _jsGetTags(Map<String, dynamic> params) async {
    final tags = tagController.tags;
    return jsonEncode(tags);
  }

  /// 根据单个标签获取日记
  /// @param params.tag - 标签名称
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesByTag(Map<String, dynamic> params) async {
    final String? tag = params['tag'];
    if (tag == null || tag.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: tag'});
    }

    final entries = calendarController.getEntriesByTag(tag);
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// 根据多个标签获取日记 (AND逻辑)
  /// @param params.tags - 标签数组
  /// 返回: List<CalendarEntry> (JSON数组)
  Future<String> _jsGetEntriesByTags(Map<String, dynamic> params) async {
    final List<String> tags = params['tags'] != null ? List<String>.from(params['tags']) : [];
    if (tags.isEmpty) {
      return jsonEncode([]);
    }
    final entries = calendarController.getEntriesByTags(tags);
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// 获取所有照片URL
  /// @param params - 参数对象（无参数）
  /// 返回: List<String> (JSON数组)
  Future<String> _jsGetPhotos(Map<String, dynamic> params) async {
    final photos = calendarController.getAllImages();
    return jsonEncode(photos);
  }

  /// 根据日期范围获取照片
  /// @param params.startDate - 开始日期 (YYYY-MM-DD)
  /// @param params.endDate - 结束日期 (YYYY-MM-DD)
  /// 返回: List<{date: String, imageUrl: String, entryId: String}> (JSON数组)
  Future<String> _jsGetPhotosByDateRange(Map<String, dynamic> params) async {
    final String? startDateStr = params['startDate'];
    final String? endDateStr = params['endDate'];
    if (startDateStr == null || startDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: startDate'});
    }
    if (endDateStr == null || endDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: endDate'});
    }

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
  /// @param params - 参数对象（无参数）
  /// 返回: {todayCount, last7DaysCount, totalCount, tagCount, photoCount}
  Future<String> _jsGetStatistics(Map<String, dynamic> params) async {
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
