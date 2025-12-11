/// Diary 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Diary Repository 实现
class ServerDiaryRepository implements IDiaryRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'diary';

  ServerDiaryRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有日记
  Future<List<DiaryEntryDto>> _readAllEntries() async {
    final diaryData = await dataService.readPluginData(
      userId,
      _pluginId,
      'entries.json',
    );
    if (diaryData == null) return [];

    final entries = diaryData['entries'] as List<dynamic>? ?? [];
    return entries.map((e) => DiaryEntryDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 保存所有日记
  Future<void> _saveAllEntries(List<DiaryEntryDto> entries) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'entries.json',
      {'entries': entries.map((e) => e.toJson()).toList()},
    );
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<DiaryEntryDto>>> getEntries({
    String? startDate,
    String? endDate,
    PaginationParams? pagination,
  }) async {
    try {
      var entries = await _readAllEntries();

      // 按日期范围过滤
      if (startDate != null) {
        entries = entries.where((e) => e.date.compareTo(startDate) >= 0).toList();
      }
      if (endDate != null) {
        entries = entries.where((e) => e.date.compareTo(endDate) <= 0).toList();
      }

      // 应用分页
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
  Future<Result<DiaryEntryDto?>> getEntryByDate(String date) async {
    try {
      final entries = await _readAllEntries();
      final entry = entries.where((e) => e.date == date).firstOrNull;
      return Result.success(entry);
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> createEntry(DiaryEntryDto entry) async {
    try {
      final entries = await _readAllEntries();
      entries.add(entry);
      await _saveAllEntries(entries);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> updateEntry(String date, DiaryEntryDto entry) async {
    try {
      final entries = await _readAllEntries();
      final index = entries.indexWhere((e) => e.date == date);

      if (index == -1) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      entries[index] = entry;
      await _saveAllEntries(entries);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEntry(String date) async {
    try {
      final entries = await _readAllEntries();
      final initialLength = entries.length;
      entries.removeWhere((e) => e.date == date);

      if (entries.length == initialLength) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      await _saveAllEntries(entries);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<DiaryEntryDto>>> searchEntries(DiaryQuery query) async {
    try {
      var entries = await _readAllEntries();

      // 按日期范围过滤
      if (query.startDate != null) {
        entries = entries.where((e) => e.date.compareTo(query.startDate!) >= 0).toList();
      }
      if (query.endDate != null) {
        entries = entries.where((e) => e.date.compareTo(query.endDate!) <= 0).toList();
      }

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        entries = entries.where((e) {
          final title = e.title.toLowerCase();
          final content = e.content.toLowerCase();
          return title.contains(lowerKeyword) || content.contains(lowerKeyword);
        }).toList();
      }

      // 按心情过滤
      if (query.mood != null && query.mood!.isNotEmpty) {
        entries = entries.where((e) => e.mood == query.mood).toList();
      }

      // 应用分页
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
  Future<Result<DiaryStatsDto>> getStats() async {
    try {
      final entries = await _readAllEntries();
      final totalEntries = entries.length;
      final totalWords = entries.fold<int>(0, (sum, e) => sum + e.content.length);
      final averageWords = totalEntries > 0 ? (totalWords / totalEntries).round() : 0;

      return Result.success(DiaryStatsDto(
        totalEntries: totalEntries,
        totalWords: totalWords,
        averageWords: averageWords,
      ));
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTodayWordCount() async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final entry = await getEntryByDate(todayStr);
      if (entry.isSuccess && entry.dataOrNull != null) {
        return Result.success(entry.dataOrNull!.content.length);
      }
      return Result.success(0);
    } catch (e) {
      return Result.failure('获取今日字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getMonthWordCount() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final startStr = '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
      final endStr = '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

      final result = await getEntries(startDate: startStr, endDate: endStr);
      if (result.isSuccess) {
        final entries = result.dataOrNull ?? [];
        final totalWords = entries.fold<int>(0, (sum, e) => sum + e.content.length);
        return Result.success(totalWords);
      }
      return Result.failure('获取本月字数失败', code: ErrorCodes.serverError);
    } catch (e) {
      return Result.failure('获取本月字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<Map<String, int>>> getMonthProgress() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final totalDays = endOfMonth.day;
      final completedDays = await getEntries(
        startDate: '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01',
        endDate: '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}',
      );

      final completed = completedDays.isSuccess ? completedDays.dataOrNull?.length ?? 0 : 0;

      return Result.success({
        'completed': completed,
        'total': totalDays,
      });
    } catch (e) {
      return Result.failure('获取本月进度失败: $e', code: ErrorCodes.serverError);
    }
  }
}
