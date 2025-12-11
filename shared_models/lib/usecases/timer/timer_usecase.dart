/// Timer 插件 - UseCase 业务逻辑层
library;

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/timer/timer_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Timer 插件 UseCase - 封装所有业务逻辑
class TimerUseCase {
  final ITimerRepository repository;
  final Uuid _uuid = const Uuid();

  TimerUseCase(this.repository);

  // ============ 任务 CRUD 操作 ============

  /// 获取任务列表
  Future<Result<dynamic>> getTimerTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getTimerTasks(pagination: pagination);

      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

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
      return Result.failure('获取任务列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取任务
  Future<Result<Map<String, dynamic>?>> getTimerTaskById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getTimerTaskById(id);
      return result.map((task) => task?.toJson());
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建任务
  Future<Result<Map<String, dynamic>>> createTimerTask(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final colorValidation = ParamValidator.requireInt(params, 'color');
    if (!colorValidation.isValid) {
      return Result.failure(
        colorValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final iconCodePointValidation =
        ParamValidator.requireInt(params, 'iconCodePoint');
    if (!iconCodePointValidation.isValid) {
      return Result.failure(
        iconCodePointValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final task = TimerTaskDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        color: params['color'] as int,
        iconCodePoint: params['iconCodePoint'] as int,
        timerItems: (params['timerItems'] as List<dynamic>?)
                ?.map((e) => TimerItemDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: now,
        repeatCount: params['repeatCount'] as int? ?? 1,
        isRunning: params['isRunning'] as bool? ?? false,
        group: params['group'] as String? ?? '默认',
        enableNotification: params['enableNotification'] as bool? ?? false,
      );

      final result = await repository.createTimerTask(task);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新任务
  Future<Result<Map<String, dynamic>>> updateTimerTask(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getTimerTaskById(id);
      if (existingResult.isFailure) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        color: params['color'] as int?,
        iconCodePoint: params['iconCodePoint'] as int?,
        timerItems: params.containsKey('timerItems')
            ? (params['timerItems'] as List<dynamic>?)
                    ?.map(
                        (e) => TimerItemDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.timerItems
            : existing.timerItems,
        repeatCount: params['repeatCount'] as int?,
        isRunning: params['isRunning'] as bool?,
        group: params['group'] as String?,
        enableNotification: params['enableNotification'] as bool?,
      );

      final result = await repository.updateTimerTask(id, updated);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除任务
  Future<Result<bool>> deleteTimerTask(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteTimerTask(id);
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索任务
  Future<Result<dynamic>> searchTimerTasks(Map<String, dynamic> params) async {
    try {
      final query = TimerTaskQuery(
        group: params['group'] as String?,
        isRunning: params['isRunning'] as bool?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchTimerTasks(query);
      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

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
      return Result.failure('搜索任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 计时器项 CRUD 操作 ============

  /// 获取指定任务的计时器项列表
  Future<Result<dynamic>> getTimerItems(Map<String, dynamic> params) async {
    final taskId = params['taskId'] as String?;
    if (taskId == null || taskId.isEmpty) {
      return Result.failure(
        '缺少必需参数: taskId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result =
          await repository.getTimerItems(taskId, pagination: pagination);

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

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
      return Result.failure('获取计时器项列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取计时器项
  Future<Result<Map<String, dynamic>?>> getTimerItemById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getTimerItemById(id);
      return result.map((item) => item?.toJson());
    } catch (e) {
      return Result.failure('获取计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建计时器项
  Future<Result<Map<String, dynamic>>> createTimerItem(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final typeValidation = ParamValidator.requireInt(params, 'type');
    if (!typeValidation.isValid) {
      return Result.failure(
        typeValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final durationValidation = ParamValidator.requireInt(params, 'duration');
    if (!durationValidation.isValid) {
      return Result.failure(
        durationValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final item = TimerItemDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String?,
        type: params['type'] as int,
        duration: params['duration'] as int,
        completedDuration: params['completedDuration'] as int? ?? 0,
        isRunning: params['isRunning'] as bool? ?? false,
        workDuration: params['workDuration'] as int?,
        breakDuration: params['breakDuration'] as int?,
        cycles: params['cycles'] as int?,
        currentCycle: params['currentCycle'] as int?,
        isWorkPhase: params['isWorkPhase'] as bool?,
        repeatCount: params['repeatCount'] as int? ?? 1,
        intervalAlertDuration: params['intervalAlertDuration'] as int?,
        enableNotification: params['enableNotification'] as bool? ?? false,
      );

      final result = await repository.createTimerItem(item);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('创建计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新计时器项
  Future<Result<Map<String, dynamic>>> updateTimerItem(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getTimerItemById(id);
      if (existingResult.isFailure) {
        return Result.failure('计时器项不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('计时器项不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        description: params['description'] as String?,
        type: params['type'] as int?,
        duration: params['duration'] as int?,
        completedDuration: params['completedDuration'] as int?,
        isRunning: params['isRunning'] as bool?,
        workDuration: params['workDuration'] as int?,
        breakDuration: params['breakDuration'] as int?,
        cycles: params['cycles'] as int?,
        currentCycle: params['currentCycle'] as int?,
        isWorkPhase: params['isWorkPhase'] as bool?,
        repeatCount: params['repeatCount'] as int?,
        intervalAlertDuration: params['intervalAlertDuration'] as int?,
        enableNotification: params['enableNotification'] as bool?,
      );

      final result = await repository.updateTimerItem(id, updated);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('更新计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除计时器项
  Future<Result<bool>> deleteTimerItem(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteTimerItem(id);
    } catch (e) {
      return Result.failure('删除计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取任务总数
  Future<Result<int>> getTotalTaskCount(Map<String, dynamic> params) async {
    try {
      return repository.getTotalTaskCount();
    } catch (e) {
      return Result.failure('获取任务总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取正在运行的任务数
  Future<Result<int>> getRunningTaskCount(Map<String, dynamic> params) async {
    try {
      return repository.getRunningTaskCount();
    } catch (e) {
      return Result.failure('获取运行任务数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取指定分组的任务数
  Future<Result<int>> getTaskCountByGroup(Map<String, dynamic> params) async {
    final group = params['group'] as String?;
    if (group == null || group.isEmpty) {
      return Result.failure('缺少必需参数: group', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.getTaskCountByGroup(group);
    } catch (e) {
      return Result.failure('获取分组任务数失败: $e', code: ErrorCodes.serverError);
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
