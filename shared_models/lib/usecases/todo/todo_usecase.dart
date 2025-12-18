/// Todo 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/todo/todo_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Todo UseCase - 封装所有业务逻辑
class TodoUseCase {
  final ITodoRepository repository;
  final Uuid _uuid = const Uuid();

  TodoUseCase(this.repository);

  // ============ 任务操作 ============

  /// 获取任务列表
  ///
  /// [params] 可选参数:
  /// - `completed`: 按完成状态过滤 (bool)
  /// - `priority`: 按优先级过滤 (int: 0-3)
  /// - `category`: 按分类过滤 (string)
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getTasks(pagination: pagination);

      return result.map((tasks) {
        var filteredTasks = tasks;

        // 按完成状态过滤
        if (params.containsKey('completed')) {
          final isCompleted = params['completed'] as bool;
          filteredTasks =
              filteredTasks.where((t) => t.isCompleted == isCompleted).toList();
        }

        // 按优先级过滤
        if (params.containsKey('priority')) {
          final priority = params['priority'] as int;
          filteredTasks =
              filteredTasks.where((t) => t.priority == priority).toList();
        }

        // 按分类过滤
        if (params.containsKey('category')) {
          final category = params['category'] as String;
          filteredTasks = filteredTasks.where((t) {
            final taskCategory = t.metadata?['category'] as String?;
            return taskCategory == category;
          }).toList();
        }

        // 排序：未完成优先，然后按优先级降序，最后按创建时间降序
        filteredTasks.sort((a, b) {
          // 完成状态
          final aCompleted = a.isCompleted ? 1 : 0;
          final bCompleted = b.isCompleted ? 1 : 0;
          if (aCompleted != bCompleted) return aCompleted - bCompleted;

          // 优先级（高优先级在前）
          if (a.priority != b.priority) return b.priority - a.priority;

          // 创建时间（新的在前）
          return b.createdAt.compareTo(a.createdAt);
        });

        final jsonList = filteredTasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取任务
  Future<Result<Map<String, dynamic>?>> getTaskById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getTaskById(id);
      return result.map((t) => t?.toJson());
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建任务
  ///
  /// [params] 必需参数:
  /// - `title`: 任务标题
  /// 可选参数:
  /// - `description`: 任务描述
  /// - `priority`: 优先级 (0: 无, 1: 低, 2: 中, 3: 高)
  /// - `dueDate`: 截止日期
  /// - `tags`: 标签列表
  /// - `metadata`: 元数据 (包括 category, subtasks, reminder, repeat, notes, dueTime)
  Future<Result<Map<String, dynamic>>> createTask(
      Map<String, dynamic> params) async {
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(titleValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();

      // 解析截止日期
      DateTime? dueDate;
      if (params['dueDate'] != null) {
        final dueDateStr = params['dueDate'] as String;
        dueDate = DateTime.tryParse(dueDateStr);
      }

      // 构建元数据
      final metadata = <String, dynamic>{
        if (params['category'] != null) 'category': params['category'],
        if (params['dueTime'] != null) 'dueTime': params['dueTime'],
        if (params['subtasks'] != null) 'subtasks': params['subtasks'],
        if (params['reminder'] != null) 'reminder': params['reminder'],
        if (params['repeat'] != null) 'repeat': params['repeat'],
        if (params['notes'] != null) 'notes': params['notes'],
      };

      final task = TaskDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        description: params['description'] as String?,
        isCompleted: params['completed'] as bool? ?? false,
        priority: params['priority'] as int? ?? 0,
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
        completedAt: null,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        metadata: metadata.isNotEmpty ? metadata : null,
      );

      final result = await repository.createTask(task);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新任务
  Future<Result<Map<String, dynamic>>> updateTask(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有任务
      final existingResult = await repository.getTaskById(id);
      if (existingResult.isFailure) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      // 解析截止日期
      DateTime? dueDate = existing.dueDate;
      if (params.containsKey('dueDate')) {
        final dueDateStr = params['dueDate'] as String?;
        dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      }

      // 处理完成状态变化
      bool isCompleted = existing.isCompleted;
      DateTime? completedAt = existing.completedAt;

      if (params.containsKey('completed')) {
        final wasCompleted = existing.isCompleted;
        final nowCompleted = params['completed'] as bool;
        isCompleted = nowCompleted;

        if (!wasCompleted && nowCompleted) {
          completedAt = DateTime.now();
        } else if (wasCompleted && !nowCompleted) {
          completedAt = null;
        }
      }

      // 合并元数据
      Map<String, dynamic>? metadata = existing.metadata != null
          ? Map<String, dynamic>.from(existing.metadata!)
          : {};

      if (params.containsKey('category')) {
        metadata['category'] = params['category'];
      }
      if (params.containsKey('dueTime')) {
        metadata['dueTime'] = params['dueTime'];
      }
      if (params.containsKey('subtasks')) {
        metadata['subtasks'] = params['subtasks'];
      }
      if (params.containsKey('reminder')) {
        metadata['reminder'] = params['reminder'];
      }
      if (params.containsKey('repeat')) metadata['repeat'] = params['repeat'];
      if (params.containsKey('notes')) metadata['notes'] = params['notes'];

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        description: params.containsKey('description')
            ? params['description'] as String?
            : existing.description,
        isCompleted: isCompleted,
        priority: params['priority'] as int? ?? existing.priority,
        dueDate: dueDate,
        completedAt: completedAt,
        tags: params['tags'] != null
            ? (params['tags'] as List<dynamic>).cast<String>()
            : existing.tags,
        metadata: metadata.isNotEmpty ? metadata : null,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateTask(id, updated);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除任务
  Future<Result<Map<String, dynamic>>> deleteTask(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteTask(id);
      return result.map((_) => {'deleted': true, 'id': id});
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 完成任务
  Future<Result<Map<String, dynamic>>> completeTask(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final existingResult = await repository.getTaskById(id);
      if (existingResult.isFailure || existingResult.dataOrNull == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull!;
      if (existing.isCompleted) {
        return Result.failure('任务已完成', code: ErrorCodes.invalidParams);
      }

      final result = await repository.completeTask(id);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 取消完成任务
  Future<Result<Map<String, dynamic>>> uncompleteTask(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final existingResult = await repository.getTaskById(id);
      if (existingResult.isFailure || existingResult.dataOrNull == null) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull!;
      if (!existing.isCompleted) {
        return Result.failure('任务未完成', code: ErrorCodes.invalidParams);
      }

      final result = await repository.uncompleteTask(id);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('取消完成失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索任务
  ///
  /// [params] 可选参数:
  /// - `keyword`: 搜索关键词（标题、描述、notes）
  /// - `tags`: 标签列表（逗号分隔）
  /// - `offset`: 分页偏移
  /// - `count`: 分页数量
  Future<Result<dynamic>> searchTasks(Map<String, dynamic> params) async {
    try {
      final keyword = params['keyword'] as String?;
      final pagination = _extractPagination(params);

      final query = TaskQuery(
        keyword: keyword,
        pagination: pagination,
      );

      final result = await repository.searchTasks(query);

      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取今日任务
  Future<Result<dynamic>> getTodayTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getTodayTasks(pagination: pagination);

      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取今日任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取过期任务
  Future<Result<dynamic>> getOverdueTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getOverdueTasks(pagination: pagination);

      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取过期任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取已完成任务
  Future<Result<dynamic>> getCompletedTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getCompletedTasks(pagination: pagination);

      return result.map((tasks) {
        // 按完成时间降序排序
        final sortedTasks = List<TaskDto>.from(tasks);
        sortedTasks.sort((a, b) {
          final aTime = a.completedAt ?? a.updatedAt;
          final bTime = b.completedAt ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

        final jsonList = sortedTasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取已完成任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取待办任务
  Future<Result<dynamic>> getPendingTasks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getPendingTasks(pagination: pagination);

      return result.map((tasks) {
        final jsonList = tasks.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取待办任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取统计数据
  Future<Result<Map<String, dynamic>>> getStats(
      Map<String, dynamic> params) async {
    try {
      final statsResult = await repository.getStats();
      if (statsResult.isFailure) {
        final error = statsResult.errorOrNull!;
        return Result.failure(error.message, code: error.code);
      }

      final stats = statsResult.dataOrNull!;

      // 获取所有任务用于额外统计
      final tasksResult = await repository.getTasks();
      if (tasksResult.isFailure) {
        // 如果获取任务失败，返回基本统计信息
        return Result.success(stats.toJson());
      }

      final tasks = tasksResult.dataOrNull ?? [];
      final pendingTasks = tasks.where((t) => !t.isCompleted);

      // 按优先级统计
      final byPriority = <int, int>{};
      for (final task in pendingTasks) {
        byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;
      }

      // 按分类统计
      final byCategory = <String, int>{};
      for (final task in tasks) {
        final category = task.metadata?['category'] as String? ?? '未分类';
        byCategory[category] = (byCategory[category] ?? 0) + 1;
      }

      // 今日任务统计
      final todayTasksResult = await repository.getTodayTasks();
      final todayTasks = todayTasksResult.dataOrNull ?? [];
      final todayCompleted = todayTasks.where((t) => t.isCompleted).length;

      final completionRate = stats.total > 0
          ? (stats.completed / stats.total * 100).toStringAsFixed(1)
          : '0.0';

      return Result.success({
        'total': stats.total,
        'completed': stats.completed,
        'pending': stats.pending,
        'overdue': stats.overdue,
        'today': todayTasks.length,
        'todayCompleted': todayCompleted,
        'completionRate': completionRate,
        'byPriority': {
          'none': byPriority[0] ?? 0,
          'low': byPriority[1] ?? 0,
          'medium': byPriority[2] ?? 0,
          'high': byPriority[3] ?? 0,
        },
        'byCategory': byCategory,
      });
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
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
