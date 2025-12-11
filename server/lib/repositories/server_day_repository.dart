/// Day 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Day Repository 实现
class ServerDayRepository extends IDayRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'day';

  ServerDayRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有纪念日
  Future<List<MemorialDayDto>> _readAllMemorialDays() async {
    final daysData = await dataService.readPluginData(
      userId,
      _pluginId,
      'days.json',
    );
    if (daysData == null) return [];

    final days = daysData['days'] as List<dynamic>? ?? [];
    return days.map((d) => MemorialDayDto.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// 保存所有纪念日
  Future<void> _saveAllMemorialDays(List<MemorialDayDto> days) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'days.json',
      {'days': days.map((d) => d.toJson()).toList()},
    );
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<MemorialDayDto>>> getMemorialDays({
    String? sortMode,
    PaginationParams? pagination,
  }) async {
    try {
      var days = await _readAllMemorialDays();

      // 排序
      if (sortMode != null) {
        switch (sortMode) {
          case 'upcoming':
            days.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
            break;
          case 'recent':
            days.sort((a, b) => b.targetDate.compareTo(a.targetDate));
            break;
          case 'manual':
            days.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
            break;
        }
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          days,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(days);
    } catch (e) {
      return Result.failure('获取纪念日列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto?>> getMemorialDayById(String id) async {
    try {
      final days = await _readAllMemorialDays();
      final day = days.where((d) => d.id == id).firstOrNull;
      return Result.success(day);
    } catch (e) {
      return Result.failure('获取纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> createMemorialDay(MemorialDayDto memorialDay) async {
    try {
      final days = await _readAllMemorialDays();
      days.add(memorialDay);
      await _saveAllMemorialDays(days);
      return Result.success(memorialDay);
    } catch (e) {
      return Result.failure('创建纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> updateMemorialDay(String id, MemorialDayDto memorialDay) async {
    try {
      final days = await _readAllMemorialDays();
      final index = days.indexWhere((d) => d.id == id);

      if (index == -1) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      days[index] = memorialDay;
      await _saveAllMemorialDays(days);
      return Result.success(memorialDay);
    } catch (e) {
      return Result.failure('更新纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMemorialDay(String id) async {
    try {
      final days = await _readAllMemorialDays();
      final initialLength = days.length;
      days.removeWhere((d) => d.id == id);

      if (days.length == initialLength) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      await _saveAllMemorialDays(days);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> reorderMemorialDays(List<String> orderedIds) async {
    try {
      final days = await _readAllMemorialDays();
      final idToDay = <String, MemorialDayDto>{};
      for (final day in days) {
        idToDay[day.id] = day;
      }

      final reorderedDays = <MemorialDayDto>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        if (idToDay.containsKey(id)) {
          final day = idToDay[id]!;
          reorderedDays.add(day.copyWith(sortIndex: i));
        }
      }

      await _saveAllMemorialDays(reorderedDays);
      return Result.success(true);
    } catch (e) {
      return Result.failure('重新排序纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<MemorialDayDto>>> searchMemorialDays(MemorialDayQuery query) async {
    try {
      var days = await _readAllMemorialDays();

      // 按日期范围过滤
      if (query.startDate != null) {
        days = days.where((d) => d.targetDate.isAfter(query.startDate!)).toList();
      }
      if (query.endDate != null) {
        days = days.where((d) => d.targetDate.isBefore(query.endDate!)).toList();
      }

      // 按是否包含过期过滤
      if (query.includeExpired == false) {
        days = days.where((d) => !d.isExpired).toList();
      }

      // 排序
      if (query.sortMode != null) {
        switch (query.sortMode) {
          case 'upcoming':
            days.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
            break;
          case 'recent':
            days.sort((a, b) => b.targetDate.compareTo(a.targetDate));
            break;
          case 'manual':
            days.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
            break;
        }
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          days,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(days);
    } catch (e) {
      return Result.failure('搜索纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayStatsDto>> getStats() async {
    try {
      final days = await _readAllMemorialDays();
      final total = days.length;
      final today = DateTime.now();

      final upcoming = days.where((d) {
        final daysRemaining = d.daysRemaining;
        return daysRemaining >= 0 && daysRemaining <= 7;
      }).length;

      final todayCount = days.where((d) => d.isToday).length;

      final expired = days.where((d) => d.isExpired).length;

      return Result.success(MemorialDayStatsDto(
        total: total,
        upcoming: upcoming,
        today: todayCount,
        expired: expired,
      ));
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
