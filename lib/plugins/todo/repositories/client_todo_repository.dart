/// Todo 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 TaskController 来实现 ITodoRepository 接口
library;

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/todo/models/subtask.dart';

/// 客户端 Todo Repository 实现
class ClientTodoRepository implements ITodoRepository {
  final TaskController _taskController;

  ClientTodoRepository(this._taskController);

  // ============ 任务操作 ============

  @override
  Future<Result<List<TaskDto>>> getTasks({PaginationParams? pagination}) async {
    try {
      final tasks = _taskController.tasks;
      final dtos = tasks.map(_taskToDto).toList();

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
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto?>> getTaskById(String id) async {
    try {
      final task = _taskController.tasks.where((t) => t.id == id).firstOrNull;
      if (task == null) {
        return Result.success(null);
      }
      return Result.success(_taskToDto(task));
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> createTask(TaskDto dto) async {
    try {
      final task = _dtoToTask(dto);
      await _taskController.addTask(task);
      return Result.success(_taskToDto(task));
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> updateTask(String id, TaskDto dto) async {
    try {
      final task = _dtoToTask(dto);
      await _taskController.updateTask(task);
      return Result.success(_taskToDto(task));
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTask(String id) async {
    try {
      await _taskController.deleteTask(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> completeTask(String id) async {
    try {
      await _taskController.updateTaskStatus(id, TaskStatus.done);
      final task = _taskController.tasks.where((t) => t.id == id).first;
      return Result.success(_taskToDto(task));
    } catch (e) {
      return Result.failure('完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> uncompleteTask(String id) async {
    try {
      await _taskController.updateTaskStatus(id, TaskStatus.todo);
      final task = _taskController.tasks.where((t) => t.id == id).first;
      return Result.success(_taskToDto(task));
    } catch (e) {
      return Result.failure('取消完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> searchTasks(TaskQuery query) async {
    try {
      final tasks = _taskController.tasks;
      final matches = <Task>[];

      for (final task in tasks) {
        bool isMatch = false;

        // 关键词搜索（标题、描述）
        if (query.keyword != null && query.keyword!.isNotEmpty) {
          final keyword = query.keyword!.toLowerCase();
          final titleMatch = task.title.toLowerCase().contains(keyword);
          final descMatch =
              task.description?.toLowerCase().contains(keyword) ?? false;

          // 从 metadata 中获取 notes 进行搜索
          final notesMatch = false; // Task 模型中没有 notes 字段

          isMatch = titleMatch || descMatch || notesMatch;
        } else {
          isMatch = true;
        }

        // 标签过滤
        if (isMatch && query.tags != null && query.tags!.isNotEmpty) {
          isMatch = query.tags!.every((tag) => task.tags.contains(tag));
        }

        // 完成状态过滤
        if (isMatch && query.isCompleted != null) {
          final taskCompleted = task.status == TaskStatus.done;
          isMatch = taskCompleted == query.isCompleted!;
        }

        // 日期范围过滤
        if (isMatch && (query.dueBefore != null || query.dueAfter != null)) {
          if (task.dueDate == null) {
            isMatch = false;
          } else {
            if (query.dueBefore != null &&
                task.dueDate!.isAfter(query.dueBefore!)) {
              isMatch = false;
            }
            if (query.dueAfter != null &&
                task.dueDate!.isBefore(query.dueAfter!)) {
              isMatch = false;
            }
          }
        }

        // 通用字段匹配
        if (isMatch && query.field != null && query.value != null) {
          final taskJson = _taskToDto(task).toJson();
          final fieldValue = taskJson[query.field!]?.toString() ?? '';
          if (query.fuzzy) {
            isMatch = fieldValue.toLowerCase().contains(
              query.value!.toLowerCase(),
            );
          } else {
            isMatch = fieldValue == query.value;
          }
        }

        if (isMatch) {
          matches.add(task);
          if (!query.findAll) break; // 只找第一个
        }
      }

      final dtos = matches.map(_taskToDto).toList();

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

  @override
  Future<Result<List<TaskDto>>> getTodayTasks({
    PaginationParams? pagination,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayTasks =
          _taskController.tasks.where((task) {
            // 如果任务既没有开始日期也没有截止日期,不算今日任务
            if (task.startDate == null && task.dueDate == null) {
              return false;
            }

            // 标准化日期(去掉时间部分)
            final startDay =
                task.startDate != null
                    ? DateTime(
                      task.startDate!.year,
                      task.startDate!.month,
                      task.startDate!.day,
                    )
                    : null;

            final dueDay =
                task.dueDate != null
                    ? DateTime(
                      task.dueDate!.year,
                      task.dueDate!.month,
                      task.dueDate!.day,
                    )
                    : null;

            // 检查任务的日期范围是否包含今天
            // 条件:startDate <= today 且 dueDate >= today
            if (startDay != null && dueDay != null) {
              // 两个日期都存在:检查今天是否在范围内
              return !startDay.isAfter(today) && !dueDay.isBefore(today);
            } else if (startDay != null) {
              // 只有开始日期:检查是否已开始(开始日期 <= 今天)
              return !startDay.isAfter(today);
            } else if (dueDay != null) {
              // 只有截止日期:检查是否未过期(截止日期 >= 今天)
              return !dueDay.isBefore(today);
            }

            return false;
          }).toList();

      final dtos = todayTasks.map(_taskToDto).toList();

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
      return Result.failure('获取今日任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getOverdueTasks({
    PaginationParams? pagination,
  }) async {
    try {
      final now = DateTime.now();

      final overdueTasks =
          _taskController.tasks.where((task) {
            // 必须未完成
            if (task.status == TaskStatus.done) return false;

            // 必须有截止日期且已过期
            if (task.dueDate != null && task.dueDate!.isBefore(now)) {
              return true;
            }

            return false;
          }).toList();

      final dtos = overdueTasks.map(_taskToDto).toList();

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
      return Result.failure('获取逾期任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getCompletedTasks({
    PaginationParams? pagination,
  }) async {
    try {
      final completedTasks =
          _taskController.tasks
              .where((t) => t.status == TaskStatus.done)
              .toList();

      // 按完成时间降序排序
      completedTasks.sort((a, b) {
        final aTime = a.completedDate ?? a.dueDate ?? a.createdAt;
        final bTime = b.completedDate ?? b.dueDate ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      final dtos = completedTasks.map(_taskToDto).toList();

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
      return Result.failure('获取已完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getPendingTasks({
    PaginationParams? pagination,
  }) async {
    try {
      final pendingTasks =
          _taskController.tasks
              .where((t) => t.status != TaskStatus.done)
              .toList();

      final dtos = pendingTasks.map(_taskToDto).toList();

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
      return Result.failure('获取待办任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskStatsDto>> getStats() async {
    try {
      final tasks = _taskController.tasks;

      final total = tasks.length;
      final completed = tasks.where((t) => t.status == TaskStatus.done).length;
      final pending = tasks.where((t) => t.status != TaskStatus.done).length;

      final now = DateTime.now();
      final overdue =
          tasks
              .where(
                (t) =>
                    t.status != TaskStatus.done &&
                    t.dueDate != null &&
                    t.dueDate!.isBefore(now),
              )
              .length;

      final today = DateTime(now.year, now.month, now.day);
      final dueToday =
          tasks
              .where(
                (t) =>
                    t.dueDate != null &&
                    t.dueDate!.year == today.year &&
                    t.dueDate!.month == today.month &&
                    t.dueDate!.day == today.day,
              )
              .length;

      return Result.success(
        TaskStatsDto(
          total: total,
          completed: completed,
          pending: pending,
          overdue: overdue,
          dueToday: dueToday,
        ),
      );
    } catch (e) {
      return Result.failure('获取统计数据失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  /// 将 Task 模型转换为 TaskDto
  TaskDto _taskToDto(Task task) {
    // 构建 metadata
    final metadata = <String, dynamic>{};
    if (task.subtasks.isNotEmpty) {
      metadata['subtasks'] = task.subtasks.map((s) => s.toJson()).toList();
    }
    if (task.reminders.isNotEmpty) {
      metadata['reminders'] =
          task.reminders.map((r) => r.toIso8601String()).toList();
    }
    if (task.icon != null) {
      metadata['icon'] = {
        'codePoint': task.icon!.codePoint,
        'fontFamily': task.icon!.fontFamily,
      };
    }
    if (task.startTime != null) {
      metadata['startTime'] = task.startTime!.toIso8601String();
    }
    if (task.duration != null) {
      metadata['duration'] = task.duration!.inMilliseconds;
    }

    return TaskDto(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.status == TaskStatus.done,
      priority: task.priority.index,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: task.startDate ?? task.createdAt, // 使用 startDate 作为 updatedAt
      completedAt: task.completedDate,
      tags: task.tags,
      metadata: metadata.isNotEmpty ? metadata : null,
    );
  }

  /// 将 TaskDto 转换为 Task 模型
  Task _dtoToTask(TaskDto dto) {
    // 从 metadata 中提取额外字段
    final subtasks = <Subtask>[];
    final reminders = <DateTime>[];
    IconData? icon;
    DateTime? startTime;
    Duration? duration;

    if (dto.metadata != null) {
      final metadata = dto.metadata!;

      // 提取子任务
      if (metadata.containsKey('subtasks') && metadata['subtasks'] is List) {
        for (final subtask in metadata['subtasks']) {
          if (subtask is Map<String, dynamic>) {
            subtasks.add(Subtask.fromJson(subtask));
          }
        }
      }

      // 提取提醒
      if (metadata.containsKey('reminders') && metadata['reminders'] is List) {
        for (final reminder in metadata['reminders']) {
          if (reminder is String) {
            reminders.add(DateTime.parse(reminder));
          }
        }
      }

      // 提取图标
      if (metadata.containsKey('icon') &&
          metadata['icon'] is Map<String, dynamic>) {
        final iconData = metadata['icon'] as Map<String, dynamic>;
        if (iconData.containsKey('codePoint') &&
            iconData.containsKey('fontFamily')) {
          icon = IconData(
            iconData['codePoint'] as int,
            fontFamily: iconData['fontFamily'] as String,
          );
        }
      }

      // 提取开始时间
      if (metadata.containsKey('startTime') &&
          metadata['startTime'] is String) {
        startTime = DateTime.parse(metadata['startTime'] as String);
      }

      // 提取持续时间
      if (metadata.containsKey('duration') && metadata['duration'] is int) {
        duration = Duration(milliseconds: metadata['duration'] as int);
      }
    }

    return Task(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      createdAt: dto.createdAt,
      startDate: dto.updatedAt != dto.createdAt ? dto.updatedAt : null,
      dueDate: dto.dueDate,
      priority: TaskPriority.values[dto.priority.clamp(0, 2)],
      status: dto.isCompleted ? TaskStatus.done : TaskStatus.todo,
      tags: List<String>.from(dto.tags),
      subtasks: subtasks,
      reminders: reminders,
      completedDate: dto.completedAt,
      startTime: startTime,
      duration: duration,
      icon: icon,
    );
  }
}
