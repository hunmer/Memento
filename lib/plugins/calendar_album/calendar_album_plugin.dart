// ignore_for_file: unintended_html_in_doc_comment

import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:shared_models/usecases/calendar_album/calendar_album_usecase.dart';
import 'widgets/calendar_album_bottom_bar.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';
import 'repositories/client_calendar_album_repository.dart';
import 'models/calendar_entry.dart';

/// 日历相册插件主视图
class CalendarAlbumMainView extends StatelessWidget {
  const CalendarAlbumMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return CalendarAlbumBottomBar(plugin: CalendarAlbumPlugin.instance);
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

  CalendarController? _calendarController;
  CalendarController? get calendarController => _calendarController;

  TagController? _tagController;
  TagController? get tagController => _tagController;

  CalendarAlbumUseCase? _useCase;
  CalendarAlbumUseCase get useCase {
    if (_useCase == null) {
      throw StateError('CalendarAlbumUseCase has not been initialized');
    }
    return _useCase!;
  }

  @override
  String get id => 'calendar_album';

  @override
  Color get color => const Color.fromARGB(255, 245, 210, 52);

  @override
  IconData get icon => Icons.notes_rounded;

  @override
  Future<void> initialize() async {
    _calendarController = CalendarController();
    _tagController = TagController(onTagsChanged: () {});

    // 初始化 UseCase
    _useCase = CalendarAlbumUseCase(
      ClientCalendarAlbumRepository(
        calendarController: _calendarController!,
        tagController: _tagController!,
      ),
    );

    await initializeDefaultData();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return 'calendar_album_name'.tr;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const CalendarAlbumMainView();
  }

  // ==================== 小组件统计方法 ====================

  /// 获取总照片数
  int getTotalPhotosCount() {
    try {
      final controller = calendarController;
      if (controller == null) {
        debugPrint('calendarController 未初始化');
        return 0;
      }
      return controller.getAllImages().length;
    } catch (e) {
      debugPrint('获取总照片数失败: $e');
      return 0;
    }
  }

  /// 获取今日新增照片数
  int getTodayPhotosCount() {
    try {
      final controller = calendarController;
      if (controller == null) {
        debugPrint('calendarController 未初始化');
        return 0;
      }
      final todayEntries = controller.getEntriesForDate(DateTime.now());
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
      final controller = tagController;
      if (controller == null) {
        debugPrint('tagController 未初始化');
        return 0;
      }
      return controller.tags.length;
    } catch (e) {
      debugPrint('获取标签总数失败: $e');
      return 0;
    }
  }

  // ==================== 每周相册小组件相关方法 ====================

  /// 获取本周日记条目（用于每周相册小组件）
  /// @param weekOffset 相对于当前周的偏移量（0=当前周，1=下周，-1=上周）
  /// @param startDate 起始日期（可选，默认从周一开始）
  List<CalendarEntry> getWeeklyEntries({int weekOffset = 0, DateTime? startDate}) {
    try {
      final controller = calendarController;
      if (controller == null) {
        debugPrint('calendarController 未初始化');
        return [];
      }

      // 计算目标周的起始日期（周一）
      final now = DateTime.now();
      final currentWeekStart = _getWeekStart(now);
      final targetWeekStart = currentWeekStart.add(Duration(days: weekOffset * 7));

      final entries = <CalendarEntry>[];

      // 获取这一周每一天的日记
      for (int i = 0; i < 7; i++) {
        final date = targetWeekStart.add(Duration(days: i));
        entries.addAll(controller.getEntriesForDate(date));
      }

      // 按日期排序
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return entries;
    } catch (e) {
      debugPrint('获取本周日记失败: $e');
      return [];
    }
  }

  /// 获取指定日期的日记条目（周一到周日点击用）
  /// @param date 日期
  List<CalendarEntry> getEntriesForDate(DateTime date) {
    final controller = calendarController;
    if (controller == null) {
      debugPrint('calendarController 未初始化');
      return [];
    }
    return controller.getEntriesForDate(date);
  }

  /// 计算指定周的周开始日期（周一）
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 获取周信息（用于小组件标题显示）
  /// @param weekOffset 相对于当前周的偏移量
  Map<String, dynamic> getWeeklyInfo({int weekOffset = 0}) {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final targetWeekStart = currentWeekStart.add(Duration(days: weekOffset * 7));
    final weekEnd = targetWeekStart.add(const Duration(days: 6));

    // 计算这是第几周（基于年份）
    final yearStart = DateTime(now.year, 1, 1);
    final yearWeekStart = _getWeekStart(yearStart);
    final weekNumber = ((targetWeekStart.difference(yearWeekStart).inDays) / 7).floor() + 1;

    return {
      'weekNumber': weekNumber,
      'startDate': targetWeekStart,
      'endDate': weekEnd,
      'startDateStr': '${targetWeekStart.month}月 ${targetWeekStart.day}日',
      'endDateStr': '${weekEnd.month}月 ${weekEnd.day}日',
    };
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
                'calendar_album_name'.tr,

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
                        'calendar_album_today_diary'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController?.getTodayEntriesCount() ?? 0}',
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
                        'calendar_album_seven_days_diary'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController?.getLast7DaysEntriesCount() ?? 0} ',
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
                        'calendar_album_all_diaries'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController?.getAllEntriesCount() ?? 0} ',
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
                        'calendar_album_tag_count'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${tagController?.tags.length ?? 0} ',
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
    try {
      final result = await useCase.getEntries(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '获取日记列表失败: $e', 'items': []});
    }
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
      final result = await useCase.getEntriesByDate(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
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
  /// @param params.createdAt - 创建时间 (可选, 默认今天)
  /// @param params.tags - 标签数组 (可选)
  /// @param params.location - 位置 (可选)
  /// @param params.mood - 心情 (可选)
  /// @param params.weather - 天气 (可选)
  /// @param params.imageUrls - 图片URL数组 (可选)
  Future<String> _jsAddEntry(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }
    if (params['content'] == null) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    try {
      final result = await useCase.createEntry(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({
        'error': '添加日记失败',
        'message': e.toString(),
      });
    }
  }

  /// 更新日记条目
  /// @param params.id - 日记ID
  /// @param params.title - 新标题 (可选)
  /// @param params.content - 新内容 (可选)
  /// @param params.tags - 新标签数组 (可选)
  /// @param params.location - 新位置 (可选)
  /// @param params.mood - 新心情 (可选)
  /// @param params.weather - 新天气 (可选)
  /// @param params.imageUrls - 新图片URL数组 (可选)
  Future<String> _jsUpdateEntry(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final result = await useCase.updateEntry(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({
        'error': '更新日记失败',
        'message': e.toString(),
      });
    }
  }

  /// 删除日记条目
  /// @param params.id - 日记ID
  Future<String> _jsDeleteEntry(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': '缺少必需参数: id',
      });
    }

    try {
      final result = await useCase.deleteEntry(params);

      if (result.isFailure) {
        return jsonEncode({
          'success': false,
          'error': result.errorOrNull?.message,
        });
      }

      return jsonEncode({
        'success': true,
        'id': id,
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
  /// @param params.id - 日记ID
  Future<String> _jsGetEntryById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final result = await useCase.getEntryById(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      if (result.dataOrNull == null) {
        return jsonEncode({
          'error': '日记不存在',
          'id': id,
        });
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '获取日记失败: $e'});
    }
  }

  /// 获取所有标签
  /// @param params - 参数对象（可选）
  /// 返回: List<String> (JSON数组)
  Future<String> _jsGetTags(Map<String, dynamic> params) async {
    try {
      final result = await useCase.getTags(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'tags': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '获取标签列表失败: $e', 'tags': []});
    }
  }

  /// 根据单个标签获取日记
  /// 支持分页参数: offset, count
  Future<String> _jsGetEntriesByTag(Map<String, dynamic> params) async {
    final String? tag = params['tag'];
    if (tag == null || tag.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: tag'});
    }

    try {
      final result = await useCase.getEntriesByTag(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '根据标签获取日记失败: $e', 'items': []});
    }
  }

  /// 根据多个标签获取日记 (AND逻辑)
  /// 支持分页参数: offset, count
  Future<String> _jsGetEntriesByTags(Map<String, dynamic> params) async {
    final List<String> tags = params['tags'] != null ? List<String>.from(params['tags']) : [];
    if (tags.isEmpty) {
      return jsonEncode([]);
    }

    try {
      final result = await useCase.getEntriesByTags(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '根据多标签获取日记失败: $e', 'items': []});
    }
  }

  /// 获取所有照片URL
  /// 支持分页参数: offset, count
  Future<String> _jsGetPhotos(Map<String, dynamic> params) async {
    try {
      final result = await useCase.getAllImages(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '获取图片列表失败: $e', 'items': []});
    }
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

      final controller = calendarController;
      if (controller == null) {
        return jsonEncode({'error': 'calendarController 未初始化', 'items': []});
      }
      controller.entries.forEach((date, entries) {
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
  /// 返回: {todayEntries, last7DaysEntries, allEntries, tagsCount, photoCount}
  Future<String> _jsGetStatistics(Map<String, dynamic> params) async {
    try {
      final result = await useCase.getStats(params);

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message,
          'todayEntries': 0,
          'last7DaysEntries': 0,
          'allEntries': 0,
          'tagsCount': 0,
          'photoCount': 0,
        });
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({
        'error': '获取统计信息失败: $e',
        'todayEntries': 0,
        'last7DaysEntries': 0,
        'allEntries': 0,
        'tagsCount': 0,
        'photoCount': 0,
      });
    }
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

    try {
      // 使用 searchEntries 方法进行查找
      final searchParams = Map<String, dynamic>.from(params);
      final result = await useCase.searchEntries(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '查找日记失败: $e', 'items': []});
    }
  }

  /// 根据ID查找日记
  /// @param params.id 日记ID (必需)
  Future<String> _jsFindEntryById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final result = await useCase.getEntryById(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      if (result.dataOrNull == null) {
        return jsonEncode(null);
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '查找日记失败: $e'});
    }
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

    try {
      // 使用 searchEntries 方法进行查找
      final searchParams = Map<String, dynamic>.from(params);
      final result = await useCase.searchEntries(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message, 'items': []});
      }

      // 如果不查找所有项，只返回第一个结果
      final bool findAll = params['findAll'] ?? false;
      if (!findAll && result.dataOrNull is List) {
        final List<dynamic> entries = result.dataOrNull;
        if (entries.isEmpty) {
          return jsonEncode(null);
        }
        return jsonEncode(entries.first);
      }

      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': '查找日记失败: $e', 'items': []});
    }
  }
}
