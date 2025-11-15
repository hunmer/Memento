import 'package:flutter/material.dart';
import '../todo_plugin.dart';
import '../models/task.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Todo插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class TodoPromptReplacements {
  final TodoPlugin _plugin;

  TodoPromptReplacements(this._plugin);

  /// 获取任务数据并格式化为文本
  ///
  /// 参数:
  /// - status: 状态过滤 (可选, 'todo'/'inProgress'/'done')
  /// - priority: 优先级过滤 (可选, 'low'/'medium'/'high')
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, todo, inProgress, done, overdue } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description)
  /// - full: 完整数据 (包含所有字段)
  Future<String> getTasks(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final statusFilter = _parseStatus(params['status'] as String?);
      final priorityFilter = _parsePriority(params['priority'] as String?);

      // 2. 获取任务列表
      final allTasks = _plugin.taskController.tasks;

      // 3. 应用过滤条件
      final filteredTasks = allTasks.where((task) {
        // 状态过滤
        if (statusFilter != null && task.status != statusFilter) {
          return false;
        }

        // 优先级过滤
        if (priorityFilter != null && task.priority != priorityFilter) {
          return false;
        }

        return true;
      }).toList();

      // 4. 根据模式转换数据
      final result = _convertByMode(filteredTasks, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取任务数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取任务数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取任务统计数据
  ///
  /// 参数:
  /// - tag: 标签过滤 (可选)
  ///
  /// 返回格式: { total, todo, inProgress, done, overdue, byPriority, byTag }
  Future<String> getStats(Map<String, dynamic> params) async {
    try {
      final tag = params['tag'] as String?;
      final controller = _plugin.taskController;
      final tasks = tag != null && tag.isNotEmpty
          ? controller.getTasksByTag(tag)
          : controller.tasks;

      // 计算统计数据
      final total = tasks.length;
      final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
      final inProgress =
          tasks.where((t) => t.status == TaskStatus.inProgress).length;
      final done = tasks.where((t) => t.status == TaskStatus.done).length;

      // 计算逾期任务数
      final now = DateTime.now();
      final overdue = tasks
          .where((t) =>
              t.status != TaskStatus.done &&
              t.dueDate != null &&
              t.dueDate!.isBefore(now))
          .length;

      // 按优先级统计
      final byPriority = {
        'low': tasks.where((t) => t.priority == TaskPriority.low).length,
        'medium': tasks.where((t) => t.priority == TaskPriority.medium).length,
        'high': tasks.where((t) => t.priority == TaskPriority.high).length,
      };

      // 按标签统计
      final tagCounts = <String, int>{};
      for (final task in tasks) {
        for (final taskTag in task.tags) {
          tagCounts[taskTag] = (tagCounts[taskTag] ?? 0) + 1;
        }
      }

      // 按任务数排序，取前5个标签
      final topTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTagsList = topTags
          .take(5)
          .map((e) => {
                'tag': e.key,
                'cnt': e.value,
              })
          .toList();

      return FieldUtils.toJsonString({
        'total': total,
        'todo': todo,
        'inProgress': inProgress,
        'done': done,
        'overdue': overdue,
        'byPriority': byPriority,
        if (topTagsList.isNotEmpty) 'topTags': topTagsList,
      });
    } catch (e) {
      debugPrint('获取统计数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    List<dynamic> tasks,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(tasks);
      case AnalysisMode.compact:
        return _buildCompact(tasks);
      case AnalysisMode.full:
        return _buildFull(tasks);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 20,
  ///     "todo": 8,
  ///     "inProgress": 5,
  ///     "done": 7,
  ///     "overdue": 2
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<dynamic> tasks) {
    final total = tasks.length;
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;

    // 计算逾期任务数
    final now = DateTime.now();
    final overdue = tasks
        .where((t) =>
            t.status != TaskStatus.done &&
            t.dueDate != null &&
            t.dueDate!.isBefore(now))
        .length;

    return FieldUtils.buildSummaryResponse({
      'total': total,
      'todo': todo,
      'inProgress': inProgress,
      'done': done,
      'overdue': overdue,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 20, "overdue": 2 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "完成季度报告",
  ///       "status": "inProgress",
  ///       "priority": "high",
  ///       "due": "2025-01-20T18:00:00",
  ///       "tags": ["工作"]
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'overdue': 0},
        [],
      );
    }

    // 计算逾期任务数
    final now = DateTime.now();
    final overdue = tasks
        .where((t) =>
            t.status != TaskStatus.done &&
            t.dueDate != null &&
            t.dueDate!.isBefore(now))
        .length;

    // 简化记录（移除 description 字段）
    final compactRecords = tasks.map((task) {
      final record = <String, dynamic>{
        'id': task.id,
        'title': task.title,
        'status': _statusToString(task.status),
        'priority': _priorityToString(task.priority),
      };

      // 只添加非空字段
      if (task.dueDate != null) {
        record['due'] = FieldUtils.formatDateTime(task.dueDate);
      }
      if (task.tags.isNotEmpty) {
        record['tags'] = task.tags;
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': tasks.length,
        'overdue': overdue,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<dynamic> tasks) {
    final taskJsonList = tasks.map((t) => t.toJson()).toList();
    return FieldUtils.buildFullResponse(taskJsonList);
  }

  /// 解析状态字符串
  TaskStatus? _parseStatus(String? statusStr) {
    if (statusStr == null || statusStr.isEmpty) return null;

    switch (statusStr.toLowerCase()) {
      case 'todo':
        return TaskStatus.todo;
      case 'inprogress':
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return null;
    }
  }

  /// 解析优先级字符串
  TaskPriority? _parsePriority(String? priorityStr) {
    if (priorityStr == null || priorityStr.isEmpty) return null;

    switch (priorityStr.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return null;
    }
  }

  /// 状态枚举转字符串
  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.done:
        return 'done';
    }
  }

  /// 优先级枚举转字符串
  String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  /// 释放资源
  void dispose() {}
}
