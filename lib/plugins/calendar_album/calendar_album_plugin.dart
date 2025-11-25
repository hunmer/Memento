// ignore_for_file: unintended_html_in_doc_comment

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import 'widgets/calendar_album_bottom_bar.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';
import 'models/calendar_entry.dart';
import 'l10n/calendar_album_localizations.dart';


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
    return CalendarAlbumBottomBar(plugin: this);
  }

  // ==================== 小组件统计方法 ====================

  /// 获取总照片数
  int getTotalPhotosCount() {
    try {
      return calendarController.getAllImages().length;
    } catch (e) {
      debugPrint('获取总照片数失败: $e');
      return 0;
    }
  }

  /// 获取今日新增照片数
  int getTodayPhotosCount() {
    try {
      final todayEntries = calendarController.getEntriesForDate(DateTime.now());
      int photoCount = 0;

      for (final entry in todayEntries) {
        // 统计imageUrls中的照片
        photoCount += entry.imageUrls.length;
        // 统计Markdown内容中的照片
        photoCount += entry.extractImagesFromMarkdown().length;
      }

      return photoCount;
    } catch (e) {
      debugPrint('获取今日新增照片数失败: $e');
      return 0;
    }
  }

  /// 获取标签总数
  int getTagsCount() {
    try {
      return tagController.tags.length;
    } catch (e) {
      debugPrint('获取标签总数失败: $e');
      return 0;
    }
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
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

      // 日记查找方法
      'findEntryBy': _jsFindEntryBy,
      'findEntryById': _jsFindEntryById,
      'findEntryByTitle': _jsFindEntryByTitle,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有日记条目
  /// 支持分页参数: offset, count
  Future<String> _jsGetEntries(Map<String, dynamic> params) async {
    final allEntries = <CalendarEntry>[];
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });
    // 按创建时间倒序排序
    allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final entriesJson = allEntries.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        entriesJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(entriesJson);
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
  /// 支持分页参数: offset, count
  Future<String> _jsGetEntriesByTag(Map<String, dynamic> params) async {
    final String? tag = params['tag'];
    if (tag == null || tag.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: tag'});
    }

    final int? offset = params['offset'];
    final int? count = params['count'];

    final entries = calendarController.getEntriesByTag(tag);
    final entriesJson = entries.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        entriesJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(entriesJson);
  }

  /// 根据多个标签获取日记 (AND逻辑)
  /// 支持分页参数: offset, count
  Future<String> _jsGetEntriesByTags(Map<String, dynamic> params) async {
    final List<String> tags = params['tags'] != null ? List<String>.from(params['tags']) : [];
    if (tags.isEmpty) {
      return jsonEncode([]);
    }

    final int? offset = params['offset'];
    final int? count = params['count'];

    final entries = calendarController.getEntriesByTags(tags);
    final entriesJson = entries.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        entriesJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(entriesJson);
  }

  /// 获取所有照片URL
  /// 支持分页参数: offset, count
  Future<String> _jsGetPhotos(Map<String, dynamic> params) async {
    final int? offset = params['offset'];
    final int? count = params['count'];

    final photos = calendarController.getAllImages();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        photos,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(photos);
  }

  /// 根据日期范围获取照片
  /// 支持分页参数: offset, count
  Future<String> _jsGetPhotosByDateRange(Map<String, dynamic> params) async {
    final String? startDateStr = params['startDate'];
    final String? endDateStr = params['endDate'];
    if (startDateStr == null || startDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: startDate'});
    }
    if (endDateStr == null || endDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: endDate'});
    }

    final int? offset = params['offset'];
    final int? count = params['count'];

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

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          photos,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

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

  // ==================== 日记查找方法 ====================

  /// 通用日记查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindEntryBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 获取所有日记
    final allEntries = <CalendarEntry>[];
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });

    final List<CalendarEntry> matchedEntries = [];

    for (final entry in allEntries) {
      final entryJson = entry.toJson();

      // 检查字段是否匹配
      if (entryJson.containsKey(field) && entryJson[field] == value) {
        matchedEntries.add(entry);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      final entriesJson = matchedEntries.map((e) => e.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          entriesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(entriesJson);
    } else {
      if (matchedEntries.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedEntries.first.toJson());
    }
  }

  /// 根据ID查找日记
  /// @param params.id 日记ID (必需)
  Future<String> _jsFindEntryById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final entry = calendarController.getEntryById(id);
    if (entry == null) {
      return jsonEncode(null);
    }
    return jsonEncode(entry.toJson());
  }

  /// 根据标题查找日记
  /// @param params.title 日记标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页偏移量 (可选，与 count 配合使用)
  /// @param params.count 分页数量 (可选，默认 100)
  Future<String> _jsFindEntryByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 获取所有日记
    final allEntries = <CalendarEntry>[];
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });

    final List<CalendarEntry> matchedEntries = [];

    for (final entry in allEntries) {
      bool matches = false;
      if (fuzzy) {
        matches = entry.title.contains(title);
      } else {
        matches = entry.title == title;
      }

      if (matches) {
        matchedEntries.add(entry);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final entriesJson = matchedEntries.map((e) => e.toJson()).toList();
      if (offset != null || count != null) {
        final paginated = _paginate(
          entriesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }
      return jsonEncode(entriesJson);
    } else {
      if (matchedEntries.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedEntries.first.toJson());
    }
  }
}
