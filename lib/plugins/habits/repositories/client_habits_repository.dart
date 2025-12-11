/// Habits 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 HabitController、SkillController 和 CompletionRecordController
/// 来实现 IHabitsRepository 接口

library;

import 'package:shared_models/repositories/habits/habits_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';

/// 客户端 Habits Repository 实现
class ClientHabitsRepository implements IHabitsRepository {
  final HabitController habitController;
  final SkillController skillController;
  final CompletionRecordController recordController;

  ClientHabitsRepository({
    required this.habitController,
    required this.skillController,
    required this.recordController,
  });

  // ============ 习惯操作 ============

  @override
  Future<Result<List<HabitDto>>> getHabits({PaginationParams? pagination}) async {
    try {
      final habits = await habitController.loadHabits();
      final dtos = habits.map(_habitToDto).toList();

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
      return Result.failure('获取习惯列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<HabitDto?>> getHabitById(String id) async {
    try {
      final habits = await habitController.loadHabits();
      final habit = habits.where((h) => h.id == id).firstOrNull;
      if (habit == null) {
        return Result.success(null);
      }
      return Result.success(_habitToDto(habit));
    } catch (e) {
      return Result.failure('获取习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<HabitDto>> createHabit(HabitDto dto) async {
    try {
      final habit = _dtoToHabit(dto);
      await habitController.saveHabit(habit);
      return Result.success(_habitToDto(habit));
    } catch (e) {
      return Result.failure('创建习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<HabitDto>> updateHabit(String id, HabitDto dto) async {
    try {
      final habits = await habitController.loadHabits();
      final existingHabit = habits.where((h) => h.id == id).firstOrNull;
      if (existingHabit == null) {
        return Result.failure('习惯不存在', code: ErrorCodes.notFound);
      }

      final habit = _dtoToHabit(dto);
      await habitController.saveHabit(habit);
      return Result.success(_habitToDto(habit));
    } catch (e) {
      return Result.failure('更新习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteHabit(String id) async {
    try {
      await habitController.deleteHabit(id);
      // 同时删除该习惯的所有完成记录
      await recordController.clearAllCompletionRecords(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<HabitDto>>> searchHabits(HabitQuery query) async {
    try {
      final habits = await habitController.loadHabits();
      final matches = <Habit>[];

      for (final habit in habits) {
        bool isMatch = false;

        if (query.skillId != null) {
          isMatch = habit.skillId == query.skillId;
        } else if (query.group != null) {
          isMatch = habit.group == query.group;
        } else {
          isMatch = true; // 无过滤条件时返回所有
        }

        if (isMatch) {
          matches.add(habit);
        }
      }

      final dtos = matches.map(_habitToDto).toList();

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
      return Result.failure('搜索习惯失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 技能操作 ============

  @override
  Future<Result<List<SkillDto>>> getSkills({PaginationParams? pagination}) async {
    try {
      final skills = await skillController.loadSkills();
      final dtos = skills.map(_skillToDto).toList();

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
      return Result.failure('获取技能列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SkillDto?>> getSkillById(String id) async {
    try {
      final skill = skillController.getSkillById(id);
      if (skill == null) {
        return Result.success(null);
      }
      return Result.success(_skillToDto(skill));
    } catch (e) {
      return Result.failure('获取技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SkillDto>> createSkill(SkillDto dto) async {
    try {
      final skill = _dtoToSkill(dto);
      await skillController.saveSkill(skill);
      return Result.success(_skillToDto(skill));
    } catch (e) {
      return Result.failure('创建技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SkillDto>> updateSkill(String id, SkillDto dto) async {
    try {
      final existingSkill = skillController.getSkillById(id);
      if (existingSkill == null) {
        return Result.failure('技能不存在', code: ErrorCodes.notFound);
      }

      final skill = _dtoToSkill(dto);
      await skillController.saveSkill(skill);
      return Result.success(_skillToDto(skill));
    } catch (e) {
      return Result.failure('更新技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteSkill(String id) async {
    try {
      await skillController.deleteSkill(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<SkillDto>>> searchSkills(SkillQuery query) async {
    try {
      final skills = await skillController.loadSkills();
      final matches = <Skill>[];

      for (final skill in skills) {
        bool isMatch = false;

        if (query.group != null) {
          isMatch = skill.group == query.group;
        } else if (query.titleKeyword != null && query.titleKeyword!.isNotEmpty) {
          isMatch = skill.title.toLowerCase().contains(
            query.titleKeyword!.toLowerCase(),
          );
        } else {
          isMatch = true; // 无过滤条件时返回所有
        }

        if (isMatch) {
          matches.add(skill);
        }
      }

      final dtos = matches.map(_skillToDto).toList();

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
      return Result.failure('搜索技能失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 完成记录操作 ============

  @override
  Future<Result<List<CompletionRecordDto>>> getCompletionRecords(
    String parentId, {
    PaginationParams? pagination,
  }) async {
    try {
      final records = await recordController.getHabitCompletionRecords(parentId);
      final dtos = records.map(_recordToDto).toList();

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
      return Result.failure('获取完成记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CompletionRecordDto?>> getCompletionRecordById(String id) async {
    try {
      // 遍历所有习惯的完成记录，查找指定ID的记录
      final habitIds = recordController.getHabitIds();
      for (final habitId in habitIds) {
        final records = await recordController.getHabitCompletionRecords(habitId);
        final record = records.where((r) => r.id == id).firstOrNull;
        if (record != null) {
          return Result.success(_recordToDto(record));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CompletionRecordDto>> createCompletionRecord(
    CompletionRecordDto dto,
  ) async {
    try {
      final record = _dtoToRecord(dto);
      await recordController.saveCompletionRecord(dto.parentId, record);
      return Result.success(_recordToDto(record));
    } catch (e) {
      return Result.failure('创建完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteCompletionRecord(String id) async {
    try {
      await recordController.deleteCompletionRecord(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CompletionRecordDto>>> searchCompletionRecords(
    CompletionRecordQuery query,
  ) async {
    try {
      final records = await recordController.getHabitCompletionRecords(
        query.parentId,
      );

      // 过滤日期范围
      final filtered = records.where((record) {
        if (query.startDate != null && record.date.isBefore(query.startDate!)) {
          return false;
        }
        if (query.endDate != null && record.date.isAfter(query.endDate!)) {
          return false;
        }
        return true;
      }).toList();

      final dtos = filtered.map(_recordToDto).toList();

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
      return Result.failure('搜索完成记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<int>> getHabitTotalDuration(String habitId) async {
    try {
      final totalMinutes = await recordController.getTotalDuration(habitId);
      return Result.success(totalMinutes);
    } catch (e) {
      return Result.failure('获取总时长失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getHabitCompletionCount(String habitId) async {
    try {
      final count = await recordController.getCompletionCount(habitId);
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取完成次数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getSkillTotalDuration(String skillId) async {
    try {
      final records = await recordController.getSkillCompletionRecords(skillId);
      final totalMinutes = records.fold<int>(
        0,
        (sum, record) => sum + record.duration.inMinutes,
      );
      return Result.success(totalMinutes);
    } catch (e) {
      return Result.failure('获取技能总时长失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getSkillCompletionCount(String skillId) async {
    try {
      final records = await recordController.getSkillCompletionRecords(skillId);
      return Result.success(records.length);
    } catch (e) {
      return Result.failure('获取技能完成次数失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  HabitDto _habitToDto(Habit habit) {
    return HabitDto(
      id: habit.id,
      title: habit.title,
      notes: habit.notes,
      group: habit.group,
      icon: habit.icon,
      image: habit.image,
      reminderDays: habit.reminderDays,
      intervalDays: habit.intervalDays,
      durationMinutes: habit.durationMinutes,
      tags: habit.tags,
      skillId: habit.skillId,
    );
  }

  Habit _dtoToHabit(HabitDto dto) {
    return Habit(
      id: dto.id,
      title: dto.title,
      notes: dto.notes,
      group: dto.group,
      icon: dto.icon,
      image: dto.image,
      reminderDays: dto.reminderDays,
      intervalDays: dto.intervalDays,
      durationMinutes: dto.durationMinutes,
      tags: dto.tags,
      skillId: dto.skillId,
    );
  }

  SkillDto _skillToDto(Skill skill) {
    return SkillDto(
      id: skill.id,
      title: skill.title,
      description: skill.description,
      notes: skill.notes,
      group: skill.group,
      icon: skill.icon,
      image: skill.image,
      targetMinutes: skill.targetMinutes,
      maxDurationMinutes: skill.maxDurationMinutes,
    );
  }

  Skill _dtoToSkill(SkillDto dto) {
    return Skill(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      notes: dto.notes,
      group: dto.group,
      icon: dto.icon,
      image: dto.image,
      targetMinutes: dto.targetMinutes,
      maxDurationMinutes: dto.maxDurationMinutes,
    );
  }

  CompletionRecordDto _recordToDto(CompletionRecord record) {
    return CompletionRecordDto(
      id: record.id,
      parentId: record.parentId,
      date: record.date,
      durationSeconds: record.duration.inSeconds,
      notes: record.notes,
    );
  }

  CompletionRecord _dtoToRecord(CompletionRecordDto dto) {
    return CompletionRecord(
      id: dto.id,
      parentId: dto.parentId,
      date: dto.date,
      duration: Duration(seconds: dto.durationSeconds),
      notes: dto.notes,
    );
  }
}

/// 扩展方法，用于查找第一个匹配的元素
extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
