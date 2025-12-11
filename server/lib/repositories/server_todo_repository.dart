/// Todo 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Todo Repository 实现
class ServerTodoRepository implements ITodoRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'todo';

  ServerTodoRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有任务
  Future<List<TaskDto>> _readAllTasks() async {
    final tasksData = await dataService.readPluginData(
      userId,
      _pluginId,
      'tasks.json',
    );
    if (tasksData == null) return [];

    final tasks = tasksData['tasks'] as List<dynamic>? ?? [];
    return tasks.map((t) => TaskDto.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// 保存所有任务
  Future<void> _saveAllTasks(List<TaskDto> tasks) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'tasks.json',
      {'tasks': tasks.map((t) => t.toJson()).toList()},
    );
  }

  /// 检查任务是否过期
  bool _isOverdue(TaskDto task) {
    if (task.isCompleted) return false;
    if (task.dueDate == null) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);

    return dueDate.isBefore(todayDate);
  }

  /// 检查任务是否是今日任务
  bool _isToday(TaskDto task) {
    if (task.dueDate == null) return false;

    final today = DateTime.now();
    final dueDate = task.dueDate!;

    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  // ============ 任务操作 ============

  @override
  Future<Result<List<TaskDto>>> getTasks({PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto?>> getTaskById(String id) async {
    try {
      final tasks = await _readAllTasks();
      final task = tasks.where((t) => t.id == id).firstOrNull;
      return Result.success(task);
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> createTask(TaskDto task) async {
    try {
      final tasks = await _readAllTasks();
      tasks.add(task);
      await _saveAllTasks(tasks);
      return Result.success(task);
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> updateTask(String id, TaskDto task) async {
    try {
      final tasks = await _readAllTasks();
      final index = tasks.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      tasks[index] = task;
      await _saveAllTasks(tasks);
      return Result.success(task);
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTask(String id) async {
    try {
      final tasks = await _readAllTasks();
      final initialLength = tasks.length;
      tasks.removeWhere((t) => t.id == id);

      if (tasks.length == initialLength) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      await _saveAllTasks(tasks);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> completeTask(String id) async {
    try {
      final tasks = await _readAllTasks();
      final index = tasks.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final task = tasks[index];
      if (task.isCompleted) {
        return Result.failure('任务已完成', code: ErrorCodes.invalidParams);
      }

      final updated = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      tasks[index] = updated;
      await _saveAllTasks(tasks);
      return Result.success(updated);
    } catch (e) {
      return Result.failure('完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskDto>> uncompleteTask(String id) async {
    try {
      final tasks = await _readAllTasks();
      final index = tasks.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final task = tasks[index];
      if (!task.isCompleted) {
        return Result.failure('任务未完成', code: ErrorCodes.invalidParams);
      }

      final updated = task.copyWith(
        isCompleted: false,
        completedAt: null,
        updatedAt: DateTime.now(),
      );

      tasks[index] = updated;
      await _saveAllTasks(tasks);
      return Result.success(updated);
    } catch (e) {
      return Result.failure('取消完成失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> searchTasks(TaskQuery query) async {
    try {
      var tasks = await _readAllTasks();

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        tasks = tasks.where((t) {
          final title = t.title.toLowerCase();
          final desc = (t.description ?? '').toLowerCase();
          final notes = (t.metadata?['notes'] as String? ?? '').toLowerCase();
          final tags = t.tags.map((tag) => tag.toLowerCase()).toList();

          return title.contains(lowerKeyword) ||
              desc.contains(lowerKeyword) ||
              notes.contains(lowerKeyword) ||
              tags.any((tag) => tag.contains(lowerKeyword));
        }).toList();
      }

      // 按完成状态过滤
      if (query.isCompleted != null) {
        tasks = tasks.where((t) => t.isCompleted == query.isCompleted).toList();
      }

      // 按标签过滤
      if (query.tags != null && query.tags!.isNotEmpty) {
        tasks = tasks.where((t) {
          return query.tags!.any((tag) => t.tags.contains(tag));
        }).toList();
      }

      // 按日期范围过滤
      if (query.dueBefore != null) {
        tasks = tasks.where((t) {
          return t.dueDate != null && t.dueDate!.isBefore(query.dueBefore!);
        }).toList();
      }

      if (query.dueAfter != null) {
        tasks = tasks.where((t) {
          return t.dueDate != null && t.dueDate!.isAfter(query.dueAfter!);
        }).toList();
      }

      // 通用字段查找
      if (query.field != null && query.value != null) {
        tasks = tasks.where((task) {
          final json = task.toJson();
          final fieldValue = json[query.field]?.toString() ?? '';
          if (query.fuzzy) {
            return fieldValue.toLowerCase().contains(query.value!.toLowerCase());
          }
          return fieldValue == query.value;
        }).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('搜索任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getTodayTasks({PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();
      tasks = tasks.where(_isToday).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取今日任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getOverdueTasks({PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();
      tasks = tasks.where(_isOverdue).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取过期任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getCompletedTasks({PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();
      tasks = tasks.where((t) => t.isCompleted).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取已完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TaskDto>>> getPendingTasks({PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();
      tasks = tasks.where((t) => !t.isCompleted).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取待办任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TaskStatsDto>> getStats() async {
    try {
      final tasks = await _readAllTasks();

      final total = tasks.length;
      final completed = tasks.where((t) => t.isCompleted).length;
      final pending = total - completed;
      final overdue = tasks.where(_isOverdue).length;
      final dueToday = tasks.where(_isToday).length;

      final stats = TaskStatsDto(
        total: total,
        completed: completed,
        pending: pending,
        overdue: overdue,
        dueToday: dueToday,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }
}
