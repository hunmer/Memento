/// Calendar Album 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerCalendarAlbumRepository implements ICalendarAlbumRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'calendar_album';
  static const String _entriesKey = 'calendar_entries.json';
  static const String _tagGroupsKey = 'data/calendar_tag_groups.json';

  ServerCalendarAlbumRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<Map<String, dynamic>> _readEntriesData() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      _entriesKey,
    );
    return data ?? {};
  }

  Future<void> _saveEntriesData(Map<String, dynamic> data) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      _entriesKey,
      data,
    );
  }

  Future<List<CalendarAlbumEntryDto>> _readAllEntries() async {
    final data = await _readEntriesData();
    final entries = <CalendarAlbumEntryDto>[];

    data.forEach((dateKey, dateEntries) {
      if (dateEntries is List) {
        for (final entry in dateEntries) {
          entries.add(
            CalendarAlbumEntryDto.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          );
        }
      }
    });

    return entries;
  }

  Future<List<CalendarAlbumTagGroupDto>> _readTagGroups() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      _tagGroupsKey,
    );
    if (data == null) {
      return _getDefaultTagGroups();
    }

    final groups = data['tagGroups'] as List<dynamic>? ?? [];
    return groups
        .map(
            (e) => CalendarAlbumTagGroupDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveTagGroups(List<CalendarAlbumTagGroupDto> tagGroups) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      _tagGroupsKey,
      {'tagGroups': tagGroups.map((g) => g.toJson()).toList()},
    );
  }

  List<CalendarAlbumTagGroupDto> _getDefaultTagGroups() {
    return [
      const CalendarAlbumTagGroupDto(name: '最近使用', tags: []),
      const CalendarAlbumTagGroupDto(name: '地点', tags: ['家', '工作', '旅行']),
      const CalendarAlbumTagGroupDto(name: '活动', tags: ['生日', '聚会', '会议']),
      const CalendarAlbumTagGroupDto(
          name: '心情', tags: ['开心', '平静', '兴奋', '思考']),
    ];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ============ 日记 CRUD 操作实现 ============

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> getEntries(
      {PaginationParams? pagination}) async {
    try {
      var entries = await _readAllEntries();

      // 按创建时间倒序排列
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          entries,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(entries);
    } catch (e) {
      return Result.failure('获取日记列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto?>> getEntryById(String id) async {
    try {
      final entries = await _readAllEntries();
      final entry =
          FirstOrNullExtension(entries.where((e) => e.id == id)).firstOrNull;
      return Result.success(entry);
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByDate(
    DateTime date, {
    PaginationParams? pagination,
  }) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final entries = await _readAllEntries();
      var dateEntries = entries
          .where((e) => _normalizeDate(e.createdAt) == normalizedDate)
          .toList();

      // 按创建时间倒序排列
      dateEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dateEntries,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dateEntries);
    } catch (e) {
      return Result.failure('根据日期获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByTag(
    String tag, {
    PaginationParams? pagination,
  }) async {
    try {
      final entries = await _readAllEntries();
      var taggedEntries = entries.where((e) => e.tags.contains(tag)).toList();

      // 按创建时间倒序排列
      taggedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          taggedEntries,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(taggedEntries);
    } catch (e) {
      return Result.failure('根据标签获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByTags(
    List<String> tags, {
    PaginationParams? pagination,
  }) async {
    try {
      if (tags.isEmpty) {
        return Result.success([]);
      }

      final entries = await _readAllEntries();
      var taggedEntries = entries
          .where((e) => tags.every((tag) => e.tags.contains(tag)))
          .toList();

      // 按创建时间倒序排列
      taggedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          taggedEntries,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(taggedEntries);
    } catch (e) {
      return Result.failure('根据多标签获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> searchEntries(
    CalendarAlbumEntryQuery query,
  ) async {
    try {
      var entries = await _readAllEntries();

      // 筛选
      if (query.date != null) {
        final normalizedDate = _normalizeDate(query.date!);
        entries = entries
            .where((e) => _normalizeDate(e.createdAt) == normalizedDate)
            .toList();
      }

      if (query.tags != null && query.tags!.isNotEmpty) {
        entries = entries
            .where((e) => query.tags!.every((tag) => e.tags.contains(tag)))
            .toList();
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        entries = entries.where((e) {
          return e.title.toLowerCase().contains(keyword) ||
              e.content.toLowerCase().contains(keyword);
        }).toList();
      }

      if (query.tagKeyword != null && query.tagKeyword!.isNotEmpty) {
        final tagKeyword = query.tagKeyword!.toLowerCase();
        entries = entries.where((e) {
          return e.tags.any((tag) => tag.toLowerCase().contains(tagKeyword));
        }).toList();
      }

      // 排序
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          entries,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(entries);
    } catch (e) {
      return Result.failure('搜索日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto>> createEntry(
    CalendarAlbumEntryDto entry,
  ) async {
    try {
      final data = await _readEntriesData();
      final dateKey = _normalizeDate(entry.createdAt).toIso8601String();

      if (!data.containsKey(dateKey)) {
        data[dateKey] = [];
      }

      final entries = (data[dateKey] as List)
          .map((e) => CalendarAlbumEntryDto.fromJson(e as Map<String, dynamic>))
          .toList();

      entries.add(entry);
      data[dateKey] = entries.map((e) => e.toJson()).toList();

      await _saveEntriesData(data);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto>> updateEntry(
    String id,
    CalendarAlbumEntryDto entry,
  ) async {
    try {
      final data = await _readEntriesData();
      bool found = false;

      data.forEach((dateKey, dateEntries) {
        if (dateEntries is List) {
          final entries = dateEntries
              .map((e) =>
                  CalendarAlbumEntryDto.fromJson(e as Map<String, dynamic>))
              .toList();

          final index = entries.indexWhere((e) => e.id == id);
          if (index != -1) {
            entries[index] = entry;
            data[dateKey] = entries.map((e) => e.toJson()).toList();
            found = true;
          }
        }
      });

      if (!found) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      await _saveEntriesData(data);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEntry(String id) async {
    try {
      final data = await _readEntriesData();
      bool found = false;

      data.forEach((dateKey, dateEntries) {
        if (dateEntries is List) {
          final entries = dateEntries
              .map((e) =>
                  CalendarAlbumEntryDto.fromJson(e as Map<String, dynamic>))
              .toList();

          final initialLength = entries.length;
          entries.removeWhere((e) => e.id == id);

          if (entries.length < initialLength) {
            data[dateKey] = entries.map((e) => e.toJson()).toList();
            found = true;
          }
        }
      });

      if (!found) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      await _saveEntriesData(data);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理实现 ============

  @override
  Future<Result<List<CalendarAlbumTagGroupDto>>> getTagGroups() async {
    try {
      final tagGroups = await _readTagGroups();
      return Result.success(tagGroups);
    } catch (e) {
      return Result.failure('获取标签组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumTagGroupDto>>> updateTagGroups(
    List<CalendarAlbumTagGroupDto> tagGroups,
  ) async {
    try {
      await _saveTagGroups(tagGroups);
      return Result.success(tagGroups);
    } catch (e) {
      return Result.failure('更新标签组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumTagGroupDto>> addTag(
    String tag, {
    String? groupName,
  }) async {
    try {
      var tagGroups = await _readTagGroups();

      // 找到目标组
      CalendarAlbumTagGroupDto targetGroup;
      if (groupName != null) {
        targetGroup = tagGroups.firstWhere(
          (g) => g.name == groupName,
          orElse: () => CalendarAlbumTagGroupDto(name: groupName, tags: []),
        );
        if (!tagGroups.any((g) => g.name == groupName)) {
          tagGroups.add(targetGroup);
        }
      } else {
        targetGroup = tagGroups.firstWhere(
          (g) => g.name == '最近使用',
          orElse: () {
            final group = CalendarAlbumTagGroupDto(name: '最近使用', tags: []);
            tagGroups.insert(0, group);
            return group;
          },
        );
      }

      // 添加标签（如果不存在）
      if (!targetGroup.tags.contains(tag)) {
        final updatedGroup = targetGroup.copyWith(
          tags: [...targetGroup.tags, tag],
        );

        final index = tagGroups.indexOf(targetGroup);
        tagGroups[index] = updatedGroup;

        await _saveTagGroups(tagGroups);
      }

      return Result.success(targetGroup);
    } catch (e) {
      return Result.failure('添加标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTag(String tag) async {
    try {
      var tagGroups = await _readTagGroups();

      // 从所有组中删除标签
      for (final group in tagGroups) {
        if (group.tags.contains(tag)) {
          final updatedGroup = group.copyWith(
            tags: group.tags.where((t) => t != tag).toList(),
          );
          final index = tagGroups.indexOf(group);
          tagGroups[index] = updatedGroup;
        }
      }

      await _saveTagGroups(tagGroups);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getTags(CalendarAlbumTagQuery query) async {
    try {
      final tagGroups = await _readTagGroups();
      var tags = tagGroups.expand((g) => g.tags).toList();

      // 去重并排序
      tags = tags.toSet().toList()..sort();

      // 搜索
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        tags =
            tags.where((tag) => tag.toLowerCase().contains(keyword)).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tags,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tags);
    } catch (e) {
      return Result.failure('获取标签列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> searchTags(CalendarAlbumTagQuery query) async {
    try {
      final tagGroups = await _readTagGroups();
      var tags = tagGroups.expand((g) => g.tags).toList();

      // 去重并排序
      tags = tags.toSet().toList()..sort();

      // 搜索
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        tags =
            tags.where((tag) => tag.toLowerCase().contains(keyword)).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tags,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tags);
    } catch (e) {
      return Result.failure('搜索标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 图片相关实现 ============

  @override
  Future<Result<List<String>>> getAllImages() async {
    try {
      final entries = await _readAllEntries();
      final images = <String>{};

      for (final entry in entries) {
        images.addAll(entry.imageUrls);
        // 从 Markdown 内容中提取图片
        final markdownImages = _extractImagesFromMarkdown(entry.content);
        images.addAll(markdownImages);
      }

      return Result.success(images.toList());
    } catch (e) {
      return Result.failure('获取图片列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  List<String> _extractImagesFromMarkdown(String content) {
    final RegExp imgRegExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = imgRegExp.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  @override
  Future<Result<CalendarAlbumEntryDto?>> getEntryByImageUrl(
    String imageUrl,
  ) async {
    try {
      final entries = await _readAllEntries();

      for (final entry in entries) {
        if (entry.imageUrls.contains(imageUrl)) {
          return Result.success(entry);
        }

        final markdownImages = _extractImagesFromMarkdown(entry.content);
        if (markdownImages.contains(imageUrl)) {
          return Result.success(entry);
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计功能实现 ============

  @override
  Future<Result<CalendarAlbumStatsDto>> getStats() async {
    try {
      final entries = await _readAllEntries();
      final tagGroups = await _readTagGroups();

      // 统计今日日记数
      final today = _normalizeDate(DateTime.now());
      final todayEntries =
          entries.where((e) => _normalizeDate(e.createdAt) == today).length;

      // 统计最近7天日记数
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      final last7DaysEntries = entries
          .where((e) =>
              e.createdAt.isAfter(sevenDaysAgo) ||
              e.createdAt.isAtSameMomentAs(sevenDaysAgo))
          .length;

      // 统计所有日记数
      final allEntries = entries.length;

      // 统计标签数量
      final tags = tagGroups.expand((g) => g.tags).toSet().length;

      final stats = CalendarAlbumStatsDto(
        todayEntries: todayEntries,
        last7DaysEntries: last7DaysEntries,
        allEntries: allEntries,
        tagsCount: tags,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}

/// 扩展方法，帮助查找第一个匹配的元素
extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
