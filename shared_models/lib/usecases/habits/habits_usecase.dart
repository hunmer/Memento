/// Habits 插件 - UseCase 业务逻辑层
library;

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/habits/habits_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Habits 插件 UseCase - 封装所有业务逻辑
class HabitsUseCase {
  final IHabitsRepository repository;
  final Uuid _uuid = const Uuid();

  HabitsUseCase(this.repository);

  // ============ 习惯 CRUD 操作 ============

  /// 获取习惯列表
  Future<Result<dynamic>> getHabits(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getHabits(pagination: pagination);

      return result.map((habits) {
        final jsonList = habits.map((h) => h.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取习惯列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取习惯
  Future<Result<Map<String, dynamic>?>> getHabitById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getHabitById(id);
      return result.map((habit) => habit?.toJson());
    } catch (e) {
      return Result.failure('获取习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建习惯
  Future<Result<Map<String, dynamic>>> createHabit(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final durationValidation =
        ParamValidator.requireInt(params, 'durationMinutes');
    if (!durationValidation.isValid) {
      return Result.failure(
        durationValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final habit = HabitDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        notes: params['notes'] as String?,
        group: params['group'] as String?,
        icon: params['icon'] as String?,
        image: params['image'] as String?,
        reminderDays: (params['reminderDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        intervalDays: params['intervalDays'] as int? ?? 0,
        durationMinutes: params['durationMinutes'] as int,
        tags: (params['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        skillId: params['skillId'] as String?,
      );

      final result = await repository.createHabit(habit);
      return result.map((h) => h.toJson());
    } catch (e) {
      return Result.failure('创建习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新习惯
  Future<Result<Map<String, dynamic>>> updateHabit(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getHabitById(id);
      if (existingResult.isFailure) {
        return Result.failure('习惯不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('习惯不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String?,
        notes: params['notes'] as String?,
        group: params['group'] as String?,
        icon: params['icon'] as String?,
        image: params['image'] as String?,
        reminderDays: params.containsKey('reminderDays')
            ? (params['reminderDays'] as List<dynamic>?)
                    ?.map((e) => e as int)
                    .toList() ??
                existing.reminderDays
            : existing.reminderDays,
        intervalDays: params['intervalDays'] as int? ?? existing.intervalDays,
        durationMinutes:
            params['durationMinutes'] as int? ?? existing.durationMinutes,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.tags
            : existing.tags,
        skillId: params['skillId'] as String?,
      );

      final result = await repository.updateHabit(id, updated);
      return result.map((h) => h.toJson());
    } catch (e) {
      return Result.failure('更新习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除习惯
  Future<Result<bool>> deleteHabit(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteHabit(id);
    } catch (e) {
      return Result.failure('删除习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索习惯
  Future<Result<dynamic>> searchHabits(Map<String, dynamic> params) async {
    try {
      final query = HabitQuery(
        skillId: params['skillId'] as String?,
        group: params['group'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchHabits(query);
      return result.map((habits) {
        final jsonList = habits.map((h) => h.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 技能 CRUD 操作 ============

  /// 获取技能列表
  Future<Result<dynamic>> getSkills(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getSkills(pagination: pagination);

      return result.map((skills) {
        final jsonList = skills.map((s) => s.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取技能列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取技能
  Future<Result<Map<String, dynamic>?>> getSkillById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getSkillById(id);
      return result.map((skill) => skill?.toJson());
    } catch (e) {
      return Result.failure('获取技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建技能
  Future<Result<Map<String, dynamic>>> createSkill(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final skill = SkillDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        description: params['description'] as String?,
        notes: params['notes'] as String?,
        group: params['group'] as String?,
        icon: params['icon'] as String?,
        image: params['image'] as String?,
        targetMinutes: params['targetMinutes'] as int? ?? 0,
        maxDurationMinutes: params['maxDurationMinutes'] as int? ?? 0,
      );

      final result = await repository.createSkill(skill);
      return result.map((s) => s.toJson());
    } catch (e) {
      return Result.failure('创建技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新技能
  Future<Result<Map<String, dynamic>>> updateSkill(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getSkillById(id);
      if (existingResult.isFailure) {
        return Result.failure('技能不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('技能不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String?,
        description: params['description'] as String?,
        notes: params['notes'] as String?,
        group: params['group'] as String?,
        icon: params['icon'] as String?,
        image: params['image'] as String?,
        targetMinutes:
            params['targetMinutes'] as int? ?? existing.targetMinutes,
        maxDurationMinutes:
            params['maxDurationMinutes'] as int? ?? existing.maxDurationMinutes,
      );

      final result = await repository.updateSkill(id, updated);
      return result.map((s) => s.toJson());
    } catch (e) {
      return Result.failure('更新技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除技能
  Future<Result<bool>> deleteSkill(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteSkill(id);
    } catch (e) {
      return Result.failure('删除技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索技能
  Future<Result<dynamic>> searchSkills(Map<String, dynamic> params) async {
    try {
      final query = SkillQuery(
        group: params['group'] as String?,
        titleKeyword: params['titleKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchSkills(query);
      return result.map((skills) {
        final jsonList = skills.map((s) => s.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 完成记录 CRUD 操作 ============

  /// 获取完成记录列表
  Future<Result<dynamic>> getCompletionRecords(
      Map<String, dynamic> params) async {
    final parentId = params['parentId'] as String?;
    if (parentId == null || parentId.isEmpty) {
      return Result.failure(
        '缺少必需参数: parentId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result = await repository.getCompletionRecords(parentId,
          pagination: pagination);

      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取完成记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取完成记录
  Future<Result<Map<String, dynamic>?>> getCompletionRecordById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getCompletionRecordById(id);
      return result.map((record) => record?.toJson());
    } catch (e) {
      return Result.failure('获取完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建完成记录
  Future<Result<Map<String, dynamic>>> createCompletionRecord(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final parentIdValidation = ParamValidator.requireString(params, 'parentId');
    if (!parentIdValidation.isValid) {
      return Result.failure(
        parentIdValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final dateValidation = ParamValidator.requireString(params, 'date');
    if (!dateValidation.isValid) {
      return Result.failure(
        dateValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final durationValidation =
        ParamValidator.requireInt(params, 'durationSeconds');
    if (!durationValidation.isValid) {
      return Result.failure(
        durationValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final record = CompletionRecordDto(
        id: params['id'] as String? ?? _uuid.v4(),
        parentId: params['parentId'] as String,
        date: DateTime.parse(params['date'] as String),
        durationSeconds: params['durationSeconds'] as int,
        notes: params['notes'] as String? ?? '',
      );

      final result = await repository.createCompletionRecord(record);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('创建完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除完成记录
  Future<Result<bool>> deleteCompletionRecord(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteCompletionRecord(id);
    } catch (e) {
      return Result.failure('删除完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索完成记录
  Future<Result<dynamic>> searchCompletionRecords(
      Map<String, dynamic> params) async {
    final parentId = params['parentId'] as String?;
    if (parentId == null || parentId.isEmpty) {
      return Result.failure(
        '缺少必需参数: parentId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final query = CompletionRecordQuery(
        parentId: parentId,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : null,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchCompletionRecords(query);
      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取习惯的总时长
  Future<Result<int>> getHabitTotalDuration(Map<String, dynamic> params) async {
    final habitId = params['habitId'] as String?;
    if (habitId == null || habitId.isEmpty) {
      return Result.failure(
        '缺少必需参数: habitId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getHabitTotalDuration(habitId);
    } catch (e) {
      return Result.failure('获取总时长失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取习惯的完成次数
  Future<Result<int>> getHabitCompletionCount(
      Map<String, dynamic> params) async {
    final habitId = params['habitId'] as String?;
    if (habitId == null || habitId.isEmpty) {
      return Result.failure(
        '缺少必需参数: habitId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getHabitCompletionCount(habitId);
    } catch (e) {
      return Result.failure('获取完成次数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取技能的总时长
  Future<Result<int>> getSkillTotalDuration(Map<String, dynamic> params) async {
    final skillId = params['skillId'] as String?;
    if (skillId == null || skillId.isEmpty) {
      return Result.failure(
        '缺少必需参数: skillId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getSkillTotalDuration(skillId);
    } catch (e) {
      return Result.failure('获取技能总时长失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取技能的完成次数
  Future<Result<int>> getSkillCompletionCount(
      Map<String, dynamic> params) async {
    final skillId = params['skillId'] as String?;
    if (skillId == null || skillId.isEmpty) {
      return Result.failure(
        '缺少必需参数: skillId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getSkillCompletionCount(skillId);
    } catch (e) {
      return Result.failure('获取技能完成次数失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
