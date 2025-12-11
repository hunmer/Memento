/// Diary 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 DiaryUtils 来实现 IDiaryRepository 接口

import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/diary/models/diary_entry.dart';
import 'package:Memento/plugins/diary/utils/diary_utils.dart';

/// 客户端 Diary Repository 实现
class ClientDiaryRepository extends IDiaryRepository {
  final DiaryUtils diaryUtils;

  ClientDiaryRepository({
    required this.diaryUtils,
  });

  // ============ Repository 实现 ============

  @override
  Future<Result<List<DiaryEntryDto>>> getEntries({
    String? startDate,
    String? endDate,
    PaginationParams? pagination,
  }) async {
    try {
      final entries = await diaryUtils.loadDiaryEntries();
      var dtos = entries.values.map(_entryToDto).toList();

      // 按日期范围过滤
      if (startDate != null) {
        final start = DateTime.parse(startDate);
        dtos = dtos.where((d) => DateTime.parse(d.date).isAfter(start.subtract(const Duration(days: 1)))).toList();
      }
      if (endDate != null) {
        final end = DateTime.parse(endDate);
        dtos = dtos.where((d) => DateTime.parse(d.date).isBefore(end.add(const Duration(days: 1)))).toList();
      }

      // 按日期排序
      dtos.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取日记列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto?>> getEntryByDate(String date) async {
    try {
      final dateTime = DateTime.parse(date);
      final entry = await diaryUtils.loadDiaryEntry(dateTime);
      if (entry == null) {
        return Result.success(null);
      }
      return Result.success(_entryToDto(entry));
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> createEntry(DiaryEntryDto dto) async {
    try {
      final dateTime = DateTime.parse(dto.date);
      await diaryUtils.saveDiaryEntry(
        dateTime,
        dto.content,
        title: dto.title,
        mood: dto.mood,
      );

      // 重新加载以获取完整的 DTO
      final entry = await diaryUtils.loadDiaryEntry(dateTime);
      if (entry == null) {
        return Result.failure('创建日记失败', code: ErrorCodes.serverError);
      }

      return Result.success(_entryToDto(entry));
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> updateEntry(String date, DiaryEntryDto dto) async {
    try {
      final dateTime = DateTime.parse(date);
      await diaryUtils.saveDiaryEntry(
        dateTime,
        dto.content,
        title: dto.title,
        mood: dto.mood,
      );

      // 重新加载以获取完整的 DTO
      final entry = await diaryUtils.loadDiaryEntry(dateTime);
      if (entry == null) {
        return Result.failure('更新日记失败', code: ErrorCodes.serverError);
      }

      return Result.success(_entryToDto(entry));
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEntry(String date) async {
    try {
      final dateTime = DateTime.parse(date);
      final success = await diaryUtils.deleteDiaryEntry(dateTime);
      return Result.success(success);
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<DiaryEntryDto>>> searchEntries(DiaryQuery query) async {
    try {
      final entries = await diaryUtils.loadDiaryEntries();
      var dtos = entries.values.map(_entryToDto).toList();

      // 按日期范围过滤
      if (query.startDate != null) {
        final start = DateTime.parse(query.startDate!);
        dtos = dtos.where((d) => DateTime.parse(d.date).isAfter(start.subtract(const Duration(days: 1)))).toList();
      }
      if (query.endDate != null) {
        final end = DateTime.parse(query.endDate!);
        dtos = dtos.where((d) => DateTime.parse(d.date).isBefore(end.add(const Duration(days: 1)))).toList();
      }

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        dtos = dtos.where((d) {
          final title = d.title.toLowerCase();
          final content = d.content.toLowerCase();
          return title.contains(lowerKeyword) || content.contains(lowerKeyword);
        }).toList();
      }

      // 按心情过滤
      if (query.mood != null && query.mood!.isNotEmpty) {
        dtos = dtos.where((d) => d.mood == query.mood).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryStatsDto>> getStats() async {
    try {
      final stats = await diaryUtils.getDiaryStats();
      return Result.success(DiaryStatsDto(
        totalEntries: stats['entryCount'] as int,
        totalWords: stats['totalCharCount'] as int,
        averageWords: stats['averageCharCount'] as int,
      ));
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTodayWordCount() async {
    try {
      final count = await diaryUtils.getTodayWordCount();
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取今日字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getMonthWordCount() async {
    try {
      final count = await diaryUtils.getMonthWordCount();
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取本月字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<Map<String, int>>> getMonthProgress() async {
    try {
      final (completed, total) = await diaryUtils.getMonthProgress();
      return Result.success({
        'completed': completed,
        'total': total,
      });
    } catch (e) {
      return Result.failure('获取本月进度失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  DiaryEntryDto _entryToDto(DiaryEntry entry) {
    return DiaryEntryDto(
      date: '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
      title: entry.title,
      content: entry.content,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      mood: entry.mood,
    );
  }
}
