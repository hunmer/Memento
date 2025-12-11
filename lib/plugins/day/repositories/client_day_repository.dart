/// Day 插件 - 客户端 Repository 实现
/// 通过适配现有的 DayController 来实现 IDayRepository 接口

import 'package:shared_models/repositories/day/day_repository.dart';
import 'package:shared_models/shared_models.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/day/controllers/day_controller.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';

/// 客户端 Day Repository 实现
class ClientDayRepository implements IDayRepository {
  final DayController _controller;

  ClientDayRepository({required DayController controller})
    : _controller = controller;

  // ============ Repository 实现 ============

  @override
  Future<Result<List<MemorialDayDto>>> getMemorialDays({
    String? sortMode,
    PaginationParams? pagination,
  }) async {
    try {
      final days = _controller.memorialDays;
      final dtos = days.map(_memorialDayToDto).toList();

      // 排序
      if (sortMode != null) {
        switch (sortMode) {
          case 'upcoming':
            dtos.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
            break;
          case 'recent':
            dtos.sort((a, b) => b.targetDate.compareTo(a.targetDate));
            break;
          case 'manual':
            dtos.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
            break;
        }
      }

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
      return Result.failure('获取纪念日列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto?>> getMemorialDayById(String id) async {
    try {
      try {
        final day = _controller.memorialDays.firstWhere((d) => d.id == id);
        return Result.success(_memorialDayToDto(day));
      } catch (e) {
        return Result.success(null);
      }
    } catch (e) {
      return Result.failure('获取纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> createMemorialDay(MemorialDayDto dto) async {
    try {
      final memorialDay = _dtoToMemorialDay(dto);
      await _controller.addMemorialDay(memorialDay);
      return Result.success(_memorialDayToDto(memorialDay));
    } catch (e) {
      return Result.failure('创建纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayDto>> updateMemorialDay(
    String id,
    MemorialDayDto dto,
  ) async {
    try {
      final memorialDay = _dtoToMemorialDay(dto);
      await _controller.updateMemorialDay(memorialDay);
      return Result.success(_memorialDayToDto(memorialDay));
    } catch (e) {
      return Result.failure('更新纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMemorialDay(String id) async {
    try {
      await _controller.deleteMemorialDay(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> reorderMemorialDays(List<String> orderedIds) async {
    try {
      // 使用 DayController 的 reorderMemorialDays 方法
      // 通过比较新旧顺序找出需要移动的项目
      final currentDays = _controller.memorialDays;
      final idToIndex = <String, int>{};
      for (int i = 0; i < currentDays.length; i++) {
        idToIndex[currentDays[i].id] = i;
      }

      // 重新排序内存中的列表
      final sortedDays =
          currentDays.map((day) {
            final newIndex = orderedIds.indexOf(day.id);
            if (newIndex >= 0) {
              return day.copyWith(sortIndex: newIndex);
            }
            return day;
          }).toList();

      // 使用现有的排序逻辑
      for (int i = 0; i < sortedDays.length; i++) {
        final oldIndex = idToIndex[sortedDays[i].id] ?? i;
        if (oldIndex != i) {
          await _controller.reorderMemorialDays(oldIndex, i);
        }
      }

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
      var days = _controller.memorialDays;

      // 日期范围过滤
      if (query.startDate != null) {
        days =
            days.where((d) => d.targetDate.isAfter(query.startDate!)).toList();
      }
      if (query.endDate != null) {
        days =
            days.where((d) => d.targetDate.isBefore(query.endDate!)).toList();
      }

      // 是否包含过期的
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
            days.sort((a, b) => b.creationDate.compareTo(a.creationDate));
            break;
          case 'manual':
            days.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
            break;
          default:
            break;
        }
      }

      final dtos = days.map(_memorialDayToDto).toList();

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
      return Result.failure('搜索纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MemorialDayStatsDto>> getStats() async {
    try {
      final days = _controller.memorialDays;

      int total = days.length;
      int upcoming = 0;
      int today = 0;
      int expired = 0;

      for (final day in days) {
        if (day.isToday) {
          today++;
        } else if (day.daysRemaining > 0 && day.daysRemaining <= 7) {
          upcoming++;
        } else if (day.isExpired) {
          expired++;
        }
      }

      final stats = MemorialDayStatsDto(
        total: total,
        upcoming: upcoming,
        today: today,
        expired: expired,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  /// 将 MemorialDay 转换为 MemorialDayDto
  MemorialDayDto _memorialDayToDto(MemorialDay memorialDay) {
    return MemorialDayDto(
      id: memorialDay.id,
      title: memorialDay.title,
      creationDate: memorialDay.creationDate,
      targetDate: memorialDay.targetDate,
      notes: memorialDay.notes,
      backgroundColor: memorialDay.backgroundColor.value,
      backgroundImageUrl: memorialDay.backgroundImageUrl,
      sortIndex: memorialDay.sortIndex,
    );
  }

  /// 将 MemorialDayDto 转换为 MemorialDay
  MemorialDay _dtoToMemorialDay(MemorialDayDto dto) {
    return MemorialDay(
      id: dto.id,
      title: dto.title,
      creationDate: dto.creationDate,
      targetDate: dto.targetDate,
      notes: dto.notes,
      backgroundColor: Color(dto.backgroundColor),
      backgroundImageUrl: dto.backgroundImageUrl,
      sortIndex: dto.sortIndex,
    );
  }
}
