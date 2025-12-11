/// Activity 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Activity Repository 实现
class ServerActivityRepository extends IActivityRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'activity';

  ServerActivityRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 格式化日期为文件名格式 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 读取指定日期的活动
  Future<List<ActivityDto>> _readActivitiesForDate(String dateStr) async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'activities_$dateStr.json',
    );
    if (data == null) return [];

    // activities 文件结构: { "activities": [...] }
    final activities = data['activities'] as List<dynamic>? ?? [];
    return activities
        .map((a) => ActivityDto.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// 保存指定日期的活动
  Future<void> _saveActivitiesForDate(
    String dateStr,
    List<ActivityDto> activities,
  ) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'activities_$dateStr.json',
      {'activities': activities.map((a) => a.toJson()).toList()},
    );
  }

  // ============ 活动操作 ============

  @override
  Future<Result<List<ActivityDto>>> getActivities({
    required String date,
    PaginationParams? pagination,
  }) async {
    try {
      var activities = await _readActivitiesForDate(date);

      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          activities,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(activities);
    } catch (e) {
      return Result.failure('获取活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityDto?>> getActivityById({
    required String id,
    required String date,
  }) async {
    try {
      final activities = await _readActivitiesForDate(date);
      final activity = activities.where((a) => a.id == id).firstOrNull;
      return Result.success(activity);
    } catch (e) {
      return Result.failure('获取活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ActivityDto>> createActivity(ActivityDto activity) async {
    try {
      final dateStr = _formatDate(activity.startTime);
      final activities = await _readActivitiesForDate(dateStr);

      // 检查时间重叠，如有重叠则替换
      for (final existing in activities) {
        final hasOverlap = activity.startTime.isBefore(existing.endTime) &&
            activity.endTime.isAfter(existing.startTime);
        if (hasOverlap) {
          activities.removeWhere((a) => a.id == existing.id);
          break;
        }
      }

      // 添加新活动
      activities.add(activity);

      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      await _saveActivitiesForDate(dateStr, activities);

      return Result.success(activity);
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
      final activities = await _readActivitiesForDate(date);
      final index = activities.indexWhere((a) => a.id == id);

      if (index == -1) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      // 更新活动
      activities[index] = activity;

      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      await _saveActivitiesForDate(date, activities);

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
      final activities = await _readActivitiesForDate(date);
      final initialLength = activities.length;

      activities.removeWhere((a) => a.id == id);

      if (activities.length == initialLength) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      await _saveActivitiesForDate(date, activities);

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<ActivityStatsDto>> getTodayStats() async {
    try {
      final dateStr = _formatDate(DateTime.now());
      final activities = await _readActivitiesForDate(dateStr);

      // 计算总时长
      var totalMinutes = 0;
      for (final activity in activities) {
        totalMinutes += activity.durationMinutes;
      }

      final stats = ActivityStatsDto(
        date: dateStr,
        activityCount: activities.length,
        durationMinutes: totalMinutes,
        durationHours: totalMinutes ~/ 60,
        remainingMinutes: totalMinutes % 60,
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

      var totalActivities = 0;
      var totalMinutes = 0;
      final dailyStats = <DailyStatsDto>[];

      // 遍历日期范围
      var current = start;
      while (!current.isAfter(end)) {
        final dateStr = _formatDate(current);
        final activities = await _readActivitiesForDate(dateStr);

        var dayMinutes = 0;
        for (final activity in activities) {
          dayMinutes += activity.durationMinutes;
        }

        dailyStats.add(DailyStatsDto(
          date: dateStr,
          activityCount: activities.length,
          durationMinutes: dayMinutes,
        ));

        totalActivities += activities.length;
        totalMinutes += dayMinutes;

        current = current.add(const Duration(days: 1));
      }

      final stats = ActivityRangeStatsDto(
        startDate: startDate,
        endDate: endDate,
        totalActivities: totalActivities,
        totalMinutes: totalMinutes,
        totalHours: totalMinutes ~/ 60,
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
      final data = await dataService.readPluginData(
        userId,
        _pluginId,
        'tag_groups.json',
      );

      // tag_groups.json 是一个数组
      final tagGroups = data is List
          ? (data as List).map((g) => TagGroupDto.fromJson(g as Map<String, dynamic>)).toList()
          : <TagGroupDto>[];

      return Result.success(tagGroups);
    } catch (e) {
      return Result.failure('获取标签分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getRecentTags() async {
    try {
      final data = await dataService.readPluginData(
        userId,
        _pluginId,
        'recent_tags.json',
      );

      // recent_tags.json 是一个字符串数组
      final recentTags = data is List ? (data as List).cast<String>() : <String>[];

      return Result.success(recentTags);
    } catch (e) {
      return Result.failure('获取最近标签失败: $e', code: ErrorCodes.serverError);
    }
  }
}
