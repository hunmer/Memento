/// Activity 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 ActivityService 来实现 IActivityRepository 接口
library;

import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart'
    as activity_models;
import 'package:Memento/plugins/activity/models/tag_group.dart'
    as activity_models;
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:shared_models/shared_models.dart';

/// 客户端 Activity Repository 实现
class ClientActivityRepository implements IActivityRepository {
  final ActivityService activityService;

  ClientActivityRepository({required this.activityService});

  // ============ 活动操作 ============

  @override
  Future<Result<List<ActivityDto>>> getActivities({
    required String date,
    PaginationParams? pagination,
  }) async {
    try {
      final dateTime = DateTime.parse(date);
      final activities = await activityService.getActivitiesForDate(dateTime);

      // 转换为 DTO
      final dtos = activities.map(_activityToDto).toList();

      // 分页处理
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
      return Result.failure('获取活动列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityDto?>> getActivityById({
    required String id,
    required String date,
  }) async {
    try {
      final dateTime = DateTime.parse(date);
      final activities = await activityService.getActivitiesForDate(dateTime);

      final activity = activities.where((a) => a.id == id).firstOrNull;
      if (activity == null) {
        return Result.success(null);
      }

      return Result.success(_activityToDto(activity));
    } catch (e) {
      return Result.failure('获取活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityDto>> createActivity(ActivityDto dto) async {
    try {
      final activity = _dtoToActivity(dto);
      await activityService.saveActivity(activity);
      return Result.success(dto);
    } catch (e) {
      return Result.failure('创建活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityDto>> updateActivity({
    required String id,
    required String date,
    required ActivityDto activity,
  }) async {
    try {
      // 获取旧活动
      final dateTime = DateTime.parse(date);
      final activities = await activityService.getActivitiesForDate(dateTime);
      final oldActivity = activities.where((a) => a.id == id).firstOrNull;

      if (oldActivity == null) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      // 创建新活动
      final newActivity = _dtoToActivity(activity);
      await activityService.updateActivity(oldActivity, newActivity);

      return Result.success(activity);
    } catch (e) {
      return Result.failure('更新活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteActivity({
    required String id,
    required String date,
  }) async {
    try {
      final dateTime = DateTime.parse(date);
      final activities = await activityService.getActivitiesForDate(dateTime);

      final activity = activities.where((a) => a.id == id).firstOrNull;
      if (activity == null) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      await activityService.deleteActivity(activity);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<ActivityStatsDto>> getTodayStats() async {
    try {
      final now = DateTime.now();
      final activities = await activityService.getActivitiesForDate(now);

      // 计算活动数
      final activityCount = activities.length;

      // 计算总时长（分钟）
      int totalMinutes = 0;
      for (final activity in activities) {
        totalMinutes +=
            activity.endTime.difference(activity.startTime).inMinutes;
      }

      final durationHours = (totalMinutes / 60).floor();
      final remainingMinutes = _calculateRemainingMinutes(now);

      final stats = ActivityStatsDto(
        date:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        activityCount: activityCount,
        durationMinutes: totalMinutes,
        durationHours: durationHours,
        remainingMinutes: remainingMinutes,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取今日统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityRangeStatsDto>> getRangeStats({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      int totalActivities = 0;
      int totalMinutes = 0;
      final dailyStats = <DailyStatsDto>[];

      // 遍历日期范围
      var current = DateTime(start.year, start.month, start.day);
      final endDateTime = DateTime(end.year, end.month, end.day);

      while (current.isBefore(endDateTime) ||
          current.isAtSameMomentAs(endDateTime)) {
        final dateStr =
            '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        final activities = await activityService.getActivitiesForDate(current);

        final dayActivityCount = activities.length;
        int dayTotalMinutes = 0;
        for (final activity in activities) {
          dayTotalMinutes +=
              activity.endTime.difference(activity.startTime).inMinutes;
        }

        totalActivities += dayActivityCount;
        totalMinutes += dayTotalMinutes;

        dailyStats.add(
          DailyStatsDto(
            date: dateStr,
            activityCount: dayActivityCount,
            durationMinutes: dayTotalMinutes,
          ),
        );

        // 移动到下一天
        current = current.add(const Duration(days: 1));
      }

      final stats = ActivityRangeStatsDto(
        startDate: startDate,
        endDate: endDate,
        totalActivities: totalActivities,
        totalMinutes: totalMinutes,
        totalHours: (totalMinutes / 60).floor(),
        dailyStats: dailyStats,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取范围统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 标签操作 ============

  @override
  Future<Result<List<TagGroupDto>>> getTagGroups() async {
    try {
      final tagGroups = await activityService.getTagGroups();
      final dtos = tagGroups.map((g) => _tagGroupToDto(g)).toList();
      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取标签分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getRecentTags() async {
    try {
      final recentTags = await activityService.getRecentTags();
      return Result.success(recentTags);
    } catch (e) {
      return Result.failure('获取最近标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  ActivityDto _activityToDto(activity_models.ActivityRecord activity) {
    return ActivityDto(
      id: activity.id,
      startTime: activity.startTime,
      endTime: activity.endTime,
      title: activity.title,
      tags: activity.tags,
      description: activity.description,
      mood: activity.mood,
      metadata:
          activity.color != null
              ? {'color': activity.color!.value.toString()}
              : null,
    );
  }

  activity_models.ActivityRecord _dtoToActivity(ActivityDto dto) {
    int? colorValue;
    if (dto.metadata != null && dto.metadata!.containsKey('color')) {
      colorValue = int.tryParse(dto.metadata!['color'].toString());
    }

    return activity_models.ActivityRecord(
      id: dto.id,
      startTime: dto.startTime,
      endTime: dto.endTime,
      title: dto.title,
      tags: dto.tags,
      description: dto.description,
      mood: dto.mood,
      color: colorValue != null ? Color(colorValue) : null,
    );
  }

  TagGroupDto _tagGroupToDto(activity_models.TagGroup tagGroup) {
    return TagGroupDto(name: tagGroup.name, tags: tagGroup.tags);
  }

  /// 计算今日剩余时间（分钟）
  int _calculateRemainingMinutes(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    return endOfDay.difference(now).inMinutes;
  }
}
