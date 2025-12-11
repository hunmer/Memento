/// Calendar Album 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 CalendarController 和 TagController 来实现 ICalendarAlbumRepository 接口
library;

import 'package:shared_models/repositories/calendar_album/calendar_album_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/widgets/tag_manager_dialog/models/tag_group.dart'
    as dialog;

/// 客户端 Calendar Album Repository 实现
class ClientCalendarAlbumRepository implements ICalendarAlbumRepository {
  final CalendarController calendarController;
  final TagController tagController;

  ClientCalendarAlbumRepository({
    required this.calendarController,
    required this.tagController,
  });

  // ============ 私有辅助方法 ============

  /// 将 CalendarEntry 转换为 CalendarAlbumEntryDto
  CalendarAlbumEntryDto _entryToDto(CalendarEntry entry) {
    return CalendarAlbumEntryDto(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      tags: entry.tags.toList(),
      location: entry.location,
      mood: entry.mood,
      weather: entry.weather,
      imageUrls: entry.imageUrls.toList(),
      thumbUrls: entry.thumbUrls.toList(),
    );
  }

  /// 将 CalendarAlbumEntryDto 转换为 CalendarEntry
  CalendarEntry _dtoToEntry(CalendarAlbumEntryDto dto) {
    return CalendarEntry(
      id: dto.id,
      title: dto.title,
      content: dto.content,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      tags: dto.tags,
      location: dto.location,
      mood: dto.mood,
      weather: dto.weather,
      imageUrls: dto.imageUrls,
      thumbUrls: dto.thumbUrls,
    );
  }

  /// 应用分页
  List<T> _applyPagination<T>(List<T> items, PaginationParams? pagination) {
    if (pagination == null || !pagination.hasPagination) {
      return items;
    }

    final start = pagination.offset.clamp(0, items.length);
    final end = (start + pagination.count).clamp(start, items.length);
    return items.sublist(start, end);
  }

  // ============ 日记 CRUD 操作 ============

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> getEntries({
    PaginationParams? pagination,
  }) async {
    try {
      final allEntries = <CalendarEntry>[];
      calendarController.entries.forEach((date, entries) {
        allEntries.addAll(entries);
      });

      // 按创建时间倒序排序
      allEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final dtos = allEntries.map(_entryToDto).toList();
      final paginated = _applyPagination(dtos, pagination);

      return Result.success(paginated);
    } catch (e) {
      return Result.failure('获取日记列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto?>> getEntryById(String id) async {
    try {
      final entry = calendarController.getEntryById(id);
      if (entry == null) {
        return Result.success(null);
      }
      return Result.success(_entryToDto(entry));
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
      final entries = calendarController.getEntriesForDate(date);
      final dtos = entries.map(_entryToDto).toList();
      final paginated = _applyPagination(dtos, pagination);
      return Result.success(paginated);
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
      final entries = calendarController.getEntriesByTag(tag);
      final dtos = entries.map(_entryToDto).toList();
      final paginated = _applyPagination(dtos, pagination);
      return Result.success(paginated);
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
      final entries = calendarController.getEntriesByTags(tags);
      final dtos = entries.map(_entryToDto).toList();
      final paginated = _applyPagination(dtos, pagination);
      return Result.success(paginated);
    } catch (e) {
      return Result.failure('根据多标签获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumEntryDto>>> searchEntries(
    CalendarAlbumEntryQuery query,
  ) async {
    try {
      final allEntries = <CalendarEntry>[];
      calendarController.entries.forEach((date, entries) {
        allEntries.addAll(entries);
      });

      var filtered = allEntries;

      // 按日期过滤
      if (query.date != null) {
        filtered =
            filtered.where((entry) {
              final entryDate = DateTime(
                entry.createdAt.year,
                entry.createdAt.month,
                entry.createdAt.day,
              );
              final queryDate = DateTime(
                query.date!.year,
                query.date!.month,
                query.date!.day,
              );
              return entryDate.isAtSameMomentAs(queryDate);
            }).toList();
      }

      // 按标签过滤
      if (query.tags != null && query.tags!.isNotEmpty) {
        filtered =
            filtered.where((entry) {
              return query.tags!.every((tag) => entry.tags.contains(tag));
            }).toList();
      }

      // 按关键词搜索（标题和内容）
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        filtered =
            filtered.where((entry) {
              return entry.title.toLowerCase().contains(keyword) ||
                  entry.content.toLowerCase().contains(keyword);
            }).toList();
      }

      // 按标签关键词搜索
      if (query.tagKeyword != null && query.tagKeyword!.isNotEmpty) {
        final tagKeyword = query.tagKeyword!.toLowerCase();
        filtered =
            filtered.where((entry) {
              return entry.tags.any(
                (tag) => tag.toLowerCase().contains(tagKeyword),
              );
            }).toList();
      }

      // 排序（按创建时间倒序）
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final dtos = filtered.map(_entryToDto).toList();
      final paginated = _applyPagination(dtos, query.pagination);

      return Result.success(paginated);
    } catch (e) {
      return Result.failure('搜索日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto>> createEntry(
    CalendarAlbumEntryDto entry,
  ) async {
    try {
      final calendarEntry = _dtoToEntry(entry);
      await calendarController.addEntry(calendarEntry);
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
      final calendarEntry = _dtoToEntry(entry);
      await calendarController.updateEntry(calendarEntry);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEntry(String id) async {
    try {
      final entry = calendarController.getEntryById(id);
      if (entry == null) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }
      await calendarController.deleteEntry(entry);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理 ============

  @override
  Future<Result<List<CalendarAlbumTagGroupDto>>> getTagGroups() async {
    try {
      final groups =
          tagController.tagGroups.map((group) {
            return CalendarAlbumTagGroupDto(
              name: group.name,
              tags: List<String>.from(group.tags),
            );
          }).toList();
      return Result.success(groups);
    } catch (e) {
      return Result.failure('获取标签组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarAlbumTagGroupDto>>> updateTagGroups(
    List<CalendarAlbumTagGroupDto> tagGroups,
  ) async {
    try {
      // TagController 没有直接的更新所有标签组的方法
      // 这里需要手动更新每个标签组
      for (int i = 0; i < tagGroups.length; i++) {
        final dto = tagGroups[i];
        if (i < tagController.tagGroups.length) {
          tagController.tagGroups[i] = dialog.TagGroup(
            name: dto.name,
            tags: List<String>.from(dto.tags),
          );
        } else {
          tagController.tagGroups.add(
            dialog.TagGroup(name: dto.name, tags: List<String>.from(dto.tags)),
          );
        }
      }

      // 如果新的标签组数量少于原来的，移除多余的
      if (tagGroups.length < tagController.tagGroups.length) {
        tagController.tagGroups.removeRange(
          tagGroups.length,
          tagController.tagGroups.length,
        );
      }

      final groups =
          tagController.tagGroups.map((group) {
            return CalendarAlbumTagGroupDto(
              name: group.name,
              tags: List<String>.from(group.tags),
            );
          }).toList();
      return Result.success(groups);
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
      await tagController.addTag(tag, groupName: groupName);

      // 找到新添加的标签所属的标签组
      final group = tagController.tagGroups.firstWhere(
        (g) => g.tags.contains(tag),
        orElse: () => tagController.tagGroups.first,
      );

      return Result.success(
        CalendarAlbumTagGroupDto(
          name: group.name,
          tags: List<String>.from(group.tags),
        ),
      );
    } catch (e) {
      return Result.failure('添加标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTag(String tag) async {
    try {
      await tagController.deleteTag(tag);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getTags(CalendarAlbumTagQuery query) async {
    try {
      var tags = tagController.tags;

      // 如果有关键词搜索
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        tags =
            tags.where((tag) => tag.toLowerCase().contains(keyword)).toList();
      }

      final paginated = _applyPagination(tags, query.pagination);
      return Result.success(paginated);
    } catch (e) {
      return Result.failure('获取标签列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> searchTags(CalendarAlbumTagQuery query) async {
    try {
      var tags = tagController.tags;

      // 搜索标签
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = query.keyword!.toLowerCase();
        tags =
            tags.where((tag) => tag.toLowerCase().contains(keyword)).toList();
      }

      final paginated = _applyPagination(tags, query.pagination);
      return Result.success(paginated);
    } catch (e) {
      return Result.failure('搜索标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 图片相关 ============

  @override
  Future<Result<List<String>>> getAllImages() async {
    try {
      final images = calendarController.getAllImages();
      return Result.success(images);
    } catch (e) {
      return Result.failure('获取图片列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarAlbumEntryDto?>> getEntryByImageUrl(
    String imageUrl,
  ) async {
    try {
      final entry = calendarController.getDiaryEntryForImage(imageUrl);
      if (entry == null) {
        return Result.success(null);
      }
      return Result.success(_entryToDto(entry));
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计功能 ============

  @override
  Future<Result<CalendarAlbumStatsDto>> getStats() async {
    try {
      final stats = CalendarAlbumStatsDto(
        todayEntries: calendarController.getTodayEntriesCount(),
        last7DaysEntries: calendarController.getLast7DaysEntriesCount(),
        allEntries: calendarController.getAllEntriesCount(),
        tagsCount: tagController.tags.length,
      );
      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
