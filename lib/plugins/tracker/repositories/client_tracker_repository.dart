/// Tracker 插件 - 客户端 Repository 实现
///
/// 通过适配现有的存储系统来实现 ITrackerRepository 接口
library;

import 'package:shared_models/shared_models.dart';

/// 客户端 Tracker Repository 实现
class ClientTrackerRepository extends ITrackerRepository {
  final dynamic storage; // StorageManager 实例
  final String pluginId;

  ClientTrackerRepository({required this.storage, this.pluginId = 'tracker'});

  // ============ 内部辅助方法 ============

  Future<Map<String, dynamic>?> _readGoalsData() async {
    return await storage.read('$pluginId/goals.json');
  }

  Future<void> _writeGoalsData(Map<String, dynamic> data) async {
    await storage.write('$pluginId/goals.json', data);
  }

  Future<Map<String, dynamic>?> _readRecordsData() async {
    return await storage.read('$pluginId/records.json');
  }

  Future<void> _writeRecordsData(Map<String, dynamic> data) async {
    await storage.write('$pluginId/records.json', data);
  }

  List<GoalDto> _parseGoalsList(Map<String, dynamic>? data) {
    if (data == null) return [];
    final goals = data['goals'] as List<dynamic>? ?? [];
    return goals
        .map((g) => GoalDto.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  List<RecordDto> _parseRecordsList(Map<String, dynamic>? data) {
    if (data == null) return [];
    final records = data['records'] as List<dynamic>? ?? [];
    return records
        .map((r) => RecordDto.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<GoalDto>>> getGoals({
    String? status,
    String? group,
    PaginationParams? pagination,
  }) async {
    try {
      final data = await _readGoalsData();
      var goals = _parseGoalsList(data);

      // 按状态过滤
      if (status != null) {
        if (status == 'active') {
          goals = goals.where((g) => !g.isCompleted).toList();
        } else if (status == 'completed') {
          goals = goals.where((g) => g.isCompleted).toList();
        }
      }

      // 按分组过滤
      if (group != null && group.isNotEmpty) {
        goals = goals.where((g) => g.group == group).toList();
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          goals,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(goals);
    } catch (e) {
      return Result.failure('获取目标列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoalDto?>> getGoalById(String id) async {
    try {
      final data = await _readGoalsData();
      final goals = _parseGoalsList(data);
      final goal = goals.where((g) => g.id == id).firstOrNull;
      return Result.success(goal);
    } catch (e) {
      return Result.failure('获取目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoalDto>> createGoal(GoalDto goal) async {
    try {
      final data = await _readGoalsData();
      final goals = _parseGoalsList(data);
      goals.add(goal);
      await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});
      return Result.success(goal);
    } catch (e) {
      return Result.failure('创建目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoalDto>> updateGoal(String id, GoalDto goal) async {
    try {
      final data = await _readGoalsData();
      final goals = _parseGoalsList(data);
      final index = goals.indexWhere((g) => g.id == id);

      if (index == -1) {
        return Result.failure('目标不存在', code: ErrorCodes.notFound);
      }

      goals[index] = goal;
      await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});
      return Result.success(goal);
    } catch (e) {
      return Result.failure('更新目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteGoal(String id) async {
    try {
      final goalsData = await _readGoalsData();
      final goals = _parseGoalsList(goalsData);
      final initialLength = goals.length;
      goals.removeWhere((g) => g.id == id);

      if (goals.length == initialLength) {
        return Result.failure('目标不存在', code: ErrorCodes.notFound);
      }

      await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});

      // 同时删除相关记录
      final recordsData = await _readRecordsData();
      final records = _parseRecordsList(recordsData);
      final filteredRecords = records.where((r) => r.goalId != id).toList();
      await _writeRecordsData({
        'records': filteredRecords.map((r) => r.toJson()).toList(),
      });

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<GoalDto>>> searchGoals(GoalQuery query) async {
    try {
      final data = await _readGoalsData();
      var goals = _parseGoalsList(data);

      // 按状态过滤
      if (query.status != null) {
        if (query.status == 'active') {
          goals = goals.where((g) => !g.isCompleted).toList();
        } else if (query.status == 'completed') {
          goals = goals.where((g) => g.isCompleted).toList();
        }
      }

      // 按分组过滤
      if (query.group != null && query.group!.isNotEmpty) {
        goals = goals.where((g) => g.group == query.group).toList();
      }

      // 通用字段查找
      if (query.field != null && query.value != null) {
        goals =
            goals.where((goal) {
              final json = goal.toJson();
              final fieldValue = json[query.field]?.toString() ?? '';
              if (query.fuzzy) {
                return fieldValue.toLowerCase().contains(
                  query.value!.toLowerCase(),
                );
              }
              return fieldValue == query.value;
            }).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          goals,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(goals);
    } catch (e) {
      return Result.failure('搜索目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getAllGroups() async {
    try {
      final data = await _readGoalsData();
      final goals = _parseGoalsList(data);
      final groups = goals.map((g) => g.group).toSet().toList();
      groups.sort();
      return Result.success(groups);
    } catch (e) {
      return Result.failure('获取分组列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<RecordDto>>> getRecordsForGoal(
    String goalId, {
    PaginationParams? pagination,
  }) async {
    try {
      final data = await _readRecordsData();
      var records = _parseRecordsList(data);
      records = records.where((r) => r.goalId == goalId).toList();

      // 按记录时间排序
      records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('获取记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<RecordDto>> addRecord(RecordDto record) async {
    try {
      final recordsData = await _readRecordsData();
      final records = _parseRecordsList(recordsData);
      records.add(record);
      await _writeRecordsData({
        'records': records.map((r) => r.toJson()).toList(),
      });

      // 更新目标的 currentValue
      final goalsData = await _readGoalsData();
      final goals = _parseGoalsList(goalsData);
      final goalIndex = goals.indexWhere((g) => g.id == record.goalId);

      if (goalIndex != -1) {
        final goal = goals[goalIndex];
        final updatedGoal = goal.copyWith(
          currentValue: goal.currentValue + record.value,
        );
        goals[goalIndex] = updatedGoal;
        await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});
      }

      return Result.success(record);
    } catch (e) {
      return Result.failure('添加记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteRecord(String recordId) async {
    try {
      final recordsData = await _readRecordsData();
      final records = _parseRecordsList(recordsData);
      final recordIndex = records.indexWhere((r) => r.id == recordId);

      if (recordIndex == -1) {
        return Result.failure('记录不存在', code: ErrorCodes.notFound);
      }

      final record = records[recordIndex];
      records.removeAt(recordIndex);
      await _writeRecordsData({
        'records': records.map((r) => r.toJson()).toList(),
      });

      // 回退目标的 currentValue
      final goalsData = await _readGoalsData();
      final goals = _parseGoalsList(goalsData);
      final goalIndex = goals.indexWhere((g) => g.id == record.goalId);

      if (goalIndex != -1) {
        final goal = goals[goalIndex];
        final updatedGoal = goal.copyWith(
          currentValue: (goal.currentValue - record.value).clamp(
            0.0,
            double.infinity,
          ),
        );
        goals[goalIndex] = updatedGoal;
        await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> clearRecordsForGoal(String goalId) async {
    try {
      final recordsData = await _readRecordsData();
      final records = _parseRecordsList(recordsData);
      records.where((r) => r.goalId == goalId).toList();

      records.removeWhere((r) => r.goalId == goalId);
      await _writeRecordsData({
        'records': records.map((r) => r.toJson()).toList(),
      });

      // 重置目标的 currentValue
      final goalsData = await _readGoalsData();
      final goals = _parseGoalsList(goalsData);
      final goalIndex = goals.indexWhere((g) => g.id == goalId);

      if (goalIndex != -1) {
        final goal = goals[goalIndex];
        final updatedGoal = goal.copyWith(currentValue: 0.0);
        goals[goalIndex] = updatedGoal;
        await _writeGoalsData({'goals': goals.map((g) => g.toJson()).toList()});
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure('清空记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<RecordDto>>> searchRecords(RecordQuery query) async {
    try {
      final data = await _readRecordsData();
      var records = _parseRecordsList(data);

      // 按目标过滤
      if (query.goalId != null && query.goalId!.isNotEmpty) {
        records = records.where((r) => r.goalId == query.goalId).toList();
      }

      // 按日期范围过滤
      if (query.startDate != null) {
        records =
            records
                .where((r) => r.recordedAt.isAfter(query.startDate!))
                .toList();
      }
      if (query.endDate != null) {
        records =
            records
                .where((r) => r.recordedAt.isBefore(query.endDate!))
                .toList();
      }

      // 通用字段查找
      if (query.field != null && query.value != null) {
        records =
            records.where((record) {
              final json = record.toJson();
              final fieldValue = json[query.field]?.toString() ?? '';
              if (query.fuzzy) {
                return fieldValue.toLowerCase().contains(
                  query.value!.toLowerCase(),
                );
              }
              return fieldValue == query.value;
            }).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('搜索记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TrackerStatsDto>> getStats() async {
    try {
      final goalsData = await _readGoalsData();
      final goals = _parseGoalsList(goalsData);
      final recordsData = await _readRecordsData();
      final records = _parseRecordsList(recordsData);

      final totalGoals = goals.length;
      final activeGoals = goals.where((g) => !g.isCompleted).length;
      final completedGoals = goals.where((g) => g.isCompleted).length;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      final todayRecords =
          records.where((r) {
            final recordDate = DateTime(
              r.recordedAt.year,
              r.recordedAt.month,
              r.recordedAt.day,
            );
            return recordDate == today;
          }).length;

      final todayCompletedGoals =
          goals.where((g) {
            return g.isCompleted && g.currentValue >= g.targetValue;
          }).length;

      final monthCompletedGoals =
          goals.where((g) {
            return g.isCompleted && g.createdAt.isAfter(startOfMonth);
          }).length;

      return Result.success(
        TrackerStatsDto(
          todayCompletedGoals: todayCompletedGoals,
          monthCompletedGoals: monthCompletedGoals,
          monthAddedGoals: monthCompletedGoals,
          todayRecordCount: todayRecords,
          totalGoals: totalGoals,
          activeGoals: activeGoals,
          completedGoals: completedGoals,
        ),
      );
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
