/// Timer 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 TimerController、TimerTask 和 TimerItem 来实现 ITimerRepository 接口
library;

import 'package:shared_models/repositories/timer/timer_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:flutter/material.dart';
import '../models/timer_task.dart';
import '../models/timer_item.dart';
import '../storage/timer_controller.dart';
import '../../../../core/services/timer/models/timer_state.dart';

/// 客户端 Timer Repository 实现
class ClientTimerRepository extends ITimerRepository {
  final TimerController timerController;
  final Color pluginColor;

  ClientTimerRepository({
    required this.timerController,
    required this.pluginColor,
  });

  // ============ 任务操作 ============

  @override
  Future<Result<List<TimerTaskDto>>> getTimerTasks({
    PaginationParams? pagination,
  }) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final dtos = tasks.map(_timerTaskToDto).toList();

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
      return Result.failure('获取任务列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto?>> getTimerTaskById(String id) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final task = tasks.where((t) => t.id == id).firstOrNull;
      if (task == null) {
        return Result.success(null);
      }
      return Result.success(_timerTaskToDto(task));
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto>> createTimerTask(TimerTaskDto dto) async {
    try {
      // 将 DTO 转换为 TimerTask
      final task = _dtoToTimerTask(dto);

      // 添加到控制器
      final tasks = timerController.getTasks();
      tasks.add(task);
      await timerController.saveTasks(tasks);

      return Result.success(_timerTaskToDto(task));
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto>> updateTimerTask(
    String id,
    TimerTaskDto dto,
  ) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final index = tasks.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      // 将 DTO 转换为 TimerTask
      final updatedTask = _dtoToTimerTask(dto);
      tasks[index] = updatedTask;
      await timerController.saveTasks(tasks);

      return Result.success(_timerTaskToDto(updatedTask));
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTimerTask(String id) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final task = tasks.where((t) => t.id == id).firstOrNull;

      if (task == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      tasks.remove(task);
      await timerController.saveTasks(tasks);

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TimerTaskDto>>> searchTimerTasks(
    TimerTaskQuery query,
  ) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final matches = <TimerTask>[];

      for (final task in tasks) {
        bool isMatch = true;

        // 过滤分组
        if (query.group != null && task.group != query.group) {
          isMatch = false;
        }

        // 过滤运行状态
        if (query.isRunning != null && task.isRunning != query.isRunning) {
          isMatch = false;
        }

        if (isMatch) {
          matches.add(task);
          // Note: PaginationParams 没有 findAll 属性，这里简化处理
          // 如果不需要分页，默认只返回第一个匹配项
          if (query.pagination == null || !query.pagination!.hasPagination) {
            break;
          }
        }
      }

      final dtos = matches.map(_timerTaskToDto).toList();

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
      return Result.failure('搜索任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 计时器项操作 ============

  @override
  Future<Result<List<TimerItemDto>>> getTimerItems(
    String taskId, {
    PaginationParams? pagination,
  }) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();
      final task = tasks.where((t) => t.id == taskId).firstOrNull;

      if (task == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final dtos = task.timerItems.map(_timerItemToDto).toList();

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
      return Result.failure('获取计时器项列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto?>> getTimerItemById(String id) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();

      for (final task in tasks) {
        final item = task.timerItems.where((i) => i.id == id).firstOrNull;
        if (item != null) {
          return Result.success(_timerItemToDto(item));
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure('获取计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto>> createTimerItem(TimerItemDto dto) async {
    try {
      // TimerItem 是 TimerTask 的一部分，不能单独创建
      // 需要通过更新任务来添加计时器项
      return Result.failure(
        '请使用 updateTimerTask 添加计时器项',
        code: ErrorCodes.invalidParams,
      );
    } catch (e) {
      return Result.failure('创建计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto>> updateTimerItem(
    String id,
    TimerItemDto dto,
  ) async {
    try {
      // TimerItem 是 TimerTask 的一部分，不能单独更新
      // 需要通过更新任务来更新计时器项
      return Result.failure(
        '请使用 updateTimerTask 更新计时器项',
        code: ErrorCodes.invalidParams,
      );
    } catch (e) {
      return Result.failure('更新计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTimerItem(String id) async {
    try {
      await timerController.loadTasks();
      final tasks = timerController.getTasks();

      for (var taskIndex = 0; taskIndex < tasks.length; taskIndex++) {
        final task = tasks[taskIndex];
        final itemIndex = task.timerItems.indexWhere((i) => i.id == id);

        if (itemIndex != -1) {
          // 找到计时器项，删除它
          task.timerItems.removeAt(itemIndex);
          await timerController.saveTasks(tasks);
          return Result.success(true);
        }
      }

      return Result.failure('计时器项不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('删除计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<int>> getTotalTaskCount() async {
    try {
      await timerController.loadTasks();
      final count = timerController.getTasks().length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取任务总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getRunningTaskCount() async {
    try {
      await timerController.loadTasks();
      final count = timerController.getTasks().where((t) => t.isRunning).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取运行任务数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTaskCountByGroup(String group) async {
    try {
      await timerController.loadTasks();
      final count =
          timerController.getTasks().where((t) => t.group == group).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取分组任务数失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  TimerTaskDto _timerTaskToDto(TimerTask task) {
    return TimerTaskDto(
      id: task.id,
      name: task.name,
      color: task.color.toARGB32(),
      iconCodePoint: task.icon.codePoint,
      timerItems: task.timerItems.map(_timerItemToDto).toList(),
      createdAt: task.createdAt,
      repeatCount: task.repeatCount,
      isRunning: task.isRunning,
      group: task.group,
      enableNotification: task.enableNotification,
    );
  }

  TimerItemDto _timerItemToDto(TimerItem item) {
    return TimerItemDto(
      id: item.id,
      name: item.name,
      description: item.description,
      type: item.type.index,
      duration: item.duration.inSeconds,
      completedDuration: item.completedDuration.inSeconds,
      isRunning: item.isRunning,
      workDuration: item.workDuration?.inSeconds,
      breakDuration: item.breakDuration?.inSeconds,
      cycles: item.cycles,
      currentCycle: item.currentCycle,
      isWorkPhase: item.isWorkPhase,
      repeatCount: item.repeatCount,
      intervalAlertDuration: item.intervalAlertDuration?.inSeconds,
      enableNotification: item.enableNotification,
    );
  }

  TimerTask _dtoToTimerTask(TimerTaskDto dto) {
    return TimerTask(
      id: dto.id,
      name: dto.name,
      color: Color(dto.color),
      icon: IconData(dto.iconCodePoint, fontFamily: 'MaterialIcons'),
      timerItems: dto.timerItems.map(_dtoToTimerItem).toList(),
      createdAt: dto.createdAt,
      repeatCount: dto.repeatCount,
      isRunning: dto.isRunning,
      group: dto.group,
      enableNotification: dto.enableNotification,
    );
  }

  TimerItem _dtoToTimerItem(TimerItemDto dto) {
    return TimerItem(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      type: TimerType.values[dto.type],
      duration: Duration(seconds: dto.duration),
      completedDuration: Duration(seconds: dto.completedDuration),
      isRunning: dto.isRunning,
      workDuration:
          dto.workDuration != null
              ? Duration(seconds: dto.workDuration!)
              : null,
      breakDuration:
          dto.breakDuration != null
              ? Duration(seconds: dto.breakDuration!)
              : null,
      cycles: dto.cycles,
      currentCycle: dto.currentCycle,
      isWorkPhase: dto.isWorkPhase,
      repeatCount: dto.repeatCount,
      intervalAlertDuration:
          dto.intervalAlertDuration != null
              ? Duration(seconds: dto.intervalAlertDuration!)
              : null,
      enableNotification: dto.enableNotification,
    );
  }
}

/// 扩展方法：获取第一个匹配的元素或返回 null
extension<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }
}
