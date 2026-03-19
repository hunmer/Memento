/// Diary 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件
/// 数据结构：
/// - diary/<YYYY-MM-DD>.json - 每天的日记文件
/// - diary/diary_index.json - 索引文件（包含日期列表和统计信息）
library;

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Diary Repository 实现
class ServerDiaryRepository extends IDiaryRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'diary';
  static const String _indexFile = 'diary_index.json';

  ServerDiaryRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取索引文件
  Future<Map<String, dynamic>> _readIndex() async {
    final indexData = await dataService.readPluginData(
      userId,
      _pluginId,
      _indexFile,
    );
    if (indexData == null) return {};
    return Map<String, dynamic>.from(indexData);
  }

  /// 保存索引文件
  Future<void> _saveIndex(Map<String, dynamic> index) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      _indexFile,
      index,
    );
  }

  /// 更新索引中的条目
  Future<void> _updateIndexEntry(String dateStr, int contentLength) async {
    final index = await _readIndex();

    // 更新条目信息
    index[dateStr] = {
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // 更新总字数
    int totalCharCount = index['totalCharCount'] as int? ?? 0;
    totalCharCount += contentLength;
    index['totalCharCount'] = totalCharCount;

    await _saveIndex(index);
  }

  /// 从索引中移除条目
  Future<void> _removeIndexEntry(String dateStr, int contentLength) async {
    final index = await _readIndex();

    // 移除条目
    index.remove(dateStr);

    // 更新总字数
    int totalCharCount = index['totalCharCount'] as int? ?? 0;
    totalCharCount -= contentLength;
    index['totalCharCount'] = totalCharCount > 0 ? totalCharCount : 0;

    await _saveIndex(index);
  }

  /// 获取日记文件路径（相对于插件目录）
  String _getEntryPath(String date) => '$date.json';

  /// 读取单日日记
  Future<DiaryEntryDto?> _readEntry(String date) async {
    final entryData = await dataService.readPluginData(
      userId,
      _pluginId,
      _getEntryPath(date),
    );
    if (entryData == null) return null;
    return DiaryEntryDto.fromJson(entryData);
  }

  /// 保存单日日记
  Future<void> _saveEntry(DiaryEntryDto entry) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      _getEntryPath(entry.date),
      entry.toJson(),
    );
  }

  /// 删除单日日记
  Future<bool> _deleteEntry(String date) async {
    // 注意：文件路径需要去掉插件目录前缀，因为 deletePluginFile 会自动添加
    return await dataService.deletePluginFile(
      userId,
      _pluginId,
      '$date.json',
    );
  }

  /// 读取所有日记（通过索引文件）
  Future<List<DiaryEntryDto>> _readAllEntries() async {
    final index = await _readIndex();
    final entries = <DiaryEntryDto>[];

    for (final key in index.keys) {
      // 跳过统计字段
      if (key == 'totalCharCount') continue;

      final entry = await _readEntry(key);
      if (entry != null) {
        entries.add(entry);
      }
    }

    // 按日期降序排序
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
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
        entries =
            entries.where((e) => e.date.compareTo(startDate) >= 0).toList();
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
      final entry = await _readEntry(date);
      return Result.success(entry);
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> createEntry(DiaryEntryDto entry) async {
    try {
      // 检查是否已存在
      final existing = await _readEntry(entry.date);
      if (existing != null) {
        return Result.failure('该日期已有日记', code: ErrorCodes.conflict);
      }

      // 保存日记文件
      await _saveEntry(entry);

      // 更新索引
      await _updateIndexEntry(entry.date, entry.content.length);

      return Result.success(entry);
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DiaryEntryDto>> updateEntry(
      String date, DiaryEntryDto entry) async {
    try {
      // 检查是否存在
      final existing = await _readEntry(date);
      if (existing == null) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      // 计算字数差异
      final oldLength = existing.content.length;
      final newLength = entry.content.length;
      final lengthDiff = newLength - oldLength;

      // 保存日记文件
      await _saveEntry(entry);

      // 更新索引（调整字数）
      final index = await _readIndex();
      int totalCharCount = index['totalCharCount'] as int? ?? 0;
      totalCharCount += lengthDiff;
      index['totalCharCount'] = totalCharCount;
      index[entry.date] = {
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await _saveIndex(index);

      return Result.success(entry);
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEntry(String date) async {
    try {
      // 检查是否存在
      final existing = await _readEntry(date);
      if (existing == null) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      // 获取内容长度
      final contentLength = existing.content.length;

      // 删除日记文件
      await _deleteEntry(date);

      // 从索引中移除
      await _removeIndexEntry(date, contentLength);

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
        entries = entries
            .where((e) => e.date.compareTo(query.startDate!) >= 0)
            .toList();
      }
      if (query.endDate != null) {
        entries = entries
            .where((e) => e.date.compareTo(query.endDate!) <= 0)
            .toList();
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
      final index = await _readIndex();
      final entries = await _readAllEntries();

      final totalEntries = entries.length;
      final totalWords =
          entries.fold<int>(0, (sum, e) => sum + e.content.length);
      final averageWords =
          totalEntries > 0 ? (totalWords / totalEntries).round() : 0;

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
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final entry = await _readEntry(todayStr);
      if (entry != null) {
        return Result.success(entry.content.length);
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

      final startStr =
          '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
      final endStr =
          '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

      final result = await getEntries(startDate: startStr, endDate: endStr);
      if (result.isSuccess) {
        final entries = result.dataOrNull ?? [];
        final totalWords =
            entries.fold<int>(0, (sum, e) => sum + e.content.length);
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
        startDate:
            '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01',
        endDate:
            '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}',
      );

      final completed =
          completedDays.isSuccess ? completedDays.dataOrNull?.length ?? 0 : 0;

      return Result.success({
        'completed': completed,
        'total': totalDays,
      });
    } catch (e) {
      return Result.failure('获取本月进度失败: $e', code: ErrorCodes.serverError);
    }
  }
}
