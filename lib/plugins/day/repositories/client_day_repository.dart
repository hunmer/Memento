/// Day 插件 - 客户端 Repository 实现
///
/// 通过适配现有的存储系统来实现 IDayRepository 接口

import 'package:shared_models/repositories/day/day_repository.dart';
import 'package:shared_models/shared_models.dart';

/// 客户端 Day Repository 实现
class ClientDayRepository implements IDayRepository {
  final dynamic storage; // StorageManager 实例
  final String pluginId;

  ClientDayRepository({required this.storage, this.pluginId = 'day'});

  // ============ 内部辅助方法 ============

  Future<Map<String, dynamic>?> _readDaysData() async {
    return await storage.read('${pluginId}/days.json');
  }

  Future<void> _writeDaysData(Map<String, dynamic> data) async {
    await storage.write('${pluginId}/days.json', data);
  }

  List<MemorialDayDto> _parseDaysList(Map<String, dynamic>? data) {
    if (data == null) return [];
    final days = data['days'] as List<dynamic>? ?? [];
    return days
        .map((d) => MemorialDayDto.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<MemorialDayDto>>> getMemorialDays({
    String? sortMode,
    PaginationParams? pagination,
  }) async {
    try {
      final data = await _readDaysData();
      var days = _parseDaysList(data);

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
      final data = await _readDaysData();
      final days = _parseDaysList(data);
      final day = days.where((d) => d.id == id).firstOrNull;
      return Result.success(day);
    } catch (e) {
      return Result.failure('获取纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> createMemorialDay(
    MemorialDayDto memorialDay,
  ) async {
    try {
      final data = await _readDaysData();
      final days = _parseDaysList(data);
      days.add(memorialDay);
      await _writeDaysData({'days': days.map((d) => d.toJson()).toList()});
      return Result.success(memorialDay);
    } catch (e) {
      return Result.failure('创建纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> updateMemorialDay(
    String id,
    MemorialDayDto memorialDay,
  ) async {
    try {
      final data = await _readDaysData();
      final days = _parseDaysList(data);
      final index = days.indexWhere((d) => d.id == id);

      if (index == -1) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      days[index] = memorialDay;
      await _writeDaysData({'days': days.map((d) => d.toJson()).toList()});
      return Result.success(memorialDay);
    } catch (e) {
      return Result.failure('更新纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMemorialDay(String id) async {
    try {
      final data = await _readDaysData();
      final days = _parseDaysList(data);
      final initialLength = days.length;
      days.removeWhere((d) => d.id == id);

      if (days.length == initialLength) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      await _writeDaysData({'days': days.map((d) => d.toJson()).toList()});
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> reorderMemorialDays(List<String> orderedIds) async {
    try {
      final data = await _readDaysData();
      final days = _parseDaysList(data);
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

      await _writeDaysData({
        'days': reorderedDays.map((d) => d.toJson()).toList(),
      });
      return Result.success(true);
    } catch (e) {
      return Result.failure('重新排序纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<MemorialDayDto>>> searchMemorialDays(
    MemorialDayQuery query,
  ) async {
    try {
      final data = await _readDaysData();
      var days = _parseDaysList(data);

      // 按日期范围过滤
      if (query.startDate != null) {
        days =
            days.where((d) => d.targetDate.isAfter(query.startDate!)).toList();
      }
      if (query.endDate != null) {
        days =
            days.where((d) => d.targetDate.isBefore(query.endDate!)).toList();
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
      final data = await _readDaysData();
      final days = _parseDaysList(data);
      final total = days.length;

      final upcoming =
          days.where((d) {
            final daysRemaining = d.daysRemaining;
            return daysRemaining >= 0 && daysRemaining <= 7;
          }).length;

      final todayCount = days.where((d) => d.isToday).length;

      final expired = days.where((d) => d.isExpired).length;

      return Result.success(
        MemorialDayStatsDto(
          total: total,
          upcoming: upcoming,
          today: todayCount,
          expired: expired,
        ),
      );
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
