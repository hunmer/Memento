import 'package:flutter/material.dart';
import '../timer_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';
import '../models/timer_task.dart';
import '../models/timer_item.dart';

/// Timer插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class TimerPromptReplacements {
  final TimerPlugin _plugin;

  TimerPromptReplacements(this._plugin);

  /// 获取任务列表
  ///
  /// 参数:
  /// - status: 状态筛选 (all/running/completed/pending, 默认all)
  /// - group: 分组名称 (可选)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, running, completed } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getTasks(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final status = params['status']?.toString() ?? 'all';
      final group = params['group']?.toString();

      // 2. 获取所有任务
      final allTasks = _plugin.getTasks();

      // 3. 过滤任务
      var filteredTasks = allTasks;

      // 按状态过滤
      if (status != 'all') {
        filteredTasks = filteredTasks.where((task) {
          switch (status) {
            case 'running':
              return task.isRunning;
            case 'completed':
              return task.isCompleted;
            case 'pending':
              return !task.isRunning && !task.isCompleted;
            default:
              return true;
          }
        }).toList();
      }

      // 按分组过滤
      if (group != null && group.isNotEmpty) {
        filteredTasks = filteredTasks.where((task) => task.group == group).toList();
      }

      // 4. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final taskJsonList = filteredTasks.map((task) => _taskToFullJson(task)).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          taskJsonList,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertTasksByMode(filteredTasks, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取任务列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取任务列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取指定任务详情
  ///
  /// 参数:
  /// - taskId: 任务ID (必需)
  ///
  /// 返回格式: 完整任务数据
  Future<String> getTaskById(Map<String, dynamic> params) async {
    try {
      final taskId = params['taskId']?.toString();

      if (taskId == null || taskId.isEmpty) {
        return FieldUtils.toJsonString({
          'error': '缺少必需参数: taskId',
        });
      }

      final tasks = _plugin.getTasks();
      final task = tasks.where((t) => t.id == taskId).firstOrNull;

      if (task == null) {
        return FieldUtils.toJsonString({
          'error': '未找到指定任务',
          'taskId': taskId,
        });
      }

      return FieldUtils.toJsonString(_taskToFullJson(task));
    } catch (e) {
      debugPrint('获取任务详情失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取任务详情时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取统计数据
  ///
  /// 参数:
  /// - startDate: 开始日期 (YYYY-MM-DD, 可选)
  /// - endDate: 结束日期 (YYYY-MM-DD, 可选)
  /// - groupBy: 分组方式 (day/task/group/type, 默认day)
  ///
  /// 返回格式: 统计数据
  Future<String> getStatistics(Map<String, dynamic> params) async {
    try {
      final dateRange = _parseDateRange(params);
      final groupBy = params['groupBy']?.toString() ?? 'day';

      final allTasks = _plugin.getTasks();

      // 过滤日期范围内创建的任务
      var filteredTasks = allTasks;
      if (dateRange != null) {
        filteredTasks = filteredTasks.where((task) {
          return task.createdAt.isAfter(dateRange['startDate']!) &&
              task.createdAt.isBefore(dateRange['endDate']!.add(const Duration(days: 1)));
        }).toList();
      }

      final statistics = _buildStatistics(filteredTasks, groupBy);

      return FieldUtils.toJsonString(statistics);
    } catch (e) {
      debugPrint('获取统计数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取完成历史
  ///
  /// 参数:
  /// - limit: 返回数量 (默认20)
  /// - offset: 跳过数量 (默认0)
  ///
  /// 返回格式: 已完成任务列表
  Future<String> getCompletedHistory(Map<String, dynamic> params) async {
    try {
      final limit = int.tryParse(params['limit']?.toString() ?? '20') ?? 20;
      final offset = int.tryParse(params['offset']?.toString() ?? '0') ?? 0;

      final allTasks = _plugin.getTasks();
      final completedTasks = allTasks.where((task) => task.isCompleted).toList();

      // 按创建时间倒序排序
      completedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 分页
      final paginatedTasks = completedTasks.skip(offset).take(limit).toList();

      final result = {
        'total': completedTasks.length,
        'limit': limit,
        'offset': offset,
        'tasks': paginatedTasks.map((task) => _taskToCompactJson(task)).toList(),
      };

      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取完成历史失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取完成历史时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取分组摘要
  ///
  /// 返回格式: 各分组的任务数和总时长
  Future<String> getGroupSummary(Map<String, dynamic> params) async {
    try {
      final allTasks = _plugin.getTasks();
      final groups = <String, Map<String, dynamic>>{};

      for (final task in allTasks) {
        final groupName = task.group;
        if (!groups.containsKey(groupName)) {
          groups[groupName] = {
            'name': groupName,
            'total': 0,
            'running': 0,
            'completed': 0,
            'totalDuration': 0,
          };
        }

        final group = groups[groupName]!;
        group['total'] = (group['total'] as int) + 1;

        if (task.isRunning) {
          group['running'] = (group['running'] as int) + 1;
        }

        if (task.isCompleted) {
          group['completed'] = (group['completed'] as int) + 1;
        }

        // 计算总时长(秒)
        final taskDuration = task.timerItems
            .map((item) => item.duration.inSeconds)
            .fold<int>(0, (sum, dur) => sum + dur);
        group['totalDuration'] = (group['totalDuration'] as int) + taskDuration;
      }

      final result = {
        'groups': groups.values.toList(),
      };

      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取分组摘要失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取分组摘要时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取计时器类型统计
  ///
  /// 参数:
  /// - startDate: 开始日期 (YYYY-MM-DD, 可选)
  /// - endDate: 结束日期 (YYYY-MM-DD, 可选)
  ///
  /// 返回格式: 各类型计时器的数量和总时长
  Future<String> getTimerTypeStatistics(Map<String, dynamic> params) async {
    try {
      final dateRange = _parseDateRange(params);

      final allTasks = _plugin.getTasks();

      // 过滤日期范围
      var filteredTasks = allTasks;
      if (dateRange != null) {
        filteredTasks = filteredTasks.where((task) {
          return task.createdAt.isAfter(dateRange['startDate']!) &&
              task.createdAt.isBefore(dateRange['endDate']!.add(const Duration(days: 1)));
        }).toList();
      }

      final typeStats = <String, Map<String, dynamic>>{};

      for (final task in filteredTasks) {
        for (final item in task.timerItems) {
          final typeName = item.type.name;

          if (!typeStats.containsKey(typeName)) {
            typeStats[typeName] = {
              'type': typeName,
              'count': 0,
              'totalDuration': 0,
              'completedCount': 0,
              'completedDuration': 0,
            };
          }

          final stat = typeStats[typeName]!;
          stat['count'] = (stat['count'] as int) + 1;
          stat['totalDuration'] = (stat['totalDuration'] as int) + item.duration.inSeconds;

          if (item.isCompleted) {
            stat['completedCount'] = (stat['completedCount'] as int) + 1;
            stat['completedDuration'] =
                (stat['completedDuration'] as int) + item.completedDuration.inSeconds;
          }
        }
      }

      final result = {
        'types': typeStats.values.toList(),
      };

      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取计时器类型统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取计时器类型统计时出错',
        'details': e.toString(),
      });
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 解析日期范围参数
  Map<String, DateTime>? _parseDateRange(Map<String, dynamic> params) {
    final String? startDateStr = params['startDate'] as String?;
    final String? endDateStr = params['endDate'] as String?;

    if (startDateStr == null && endDateStr == null) {
      return null;
    }

    DateTime? startDate;
    DateTime? endDate;

    if (startDateStr != null) {
      startDate = _parseDate(startDateStr);
    }

    if (endDateStr != null) {
      endDate = _parseDate(endDateStr);
    }

    // 默认日期范围
    if (startDate == null && endDate == null) {
      final now = DateTime.now();
      endDate = DateTime(now.year, now.month, now.day);
      startDate = endDate.subtract(const Duration(days: 30));
    } else if (startDate != null && endDate == null) {
      endDate = DateTime.now();
    } else if (startDate == null && endDate != null) {
      startDate = endDate.subtract(const Duration(days: 30));
    }

    return {
      'startDate': startDate!,
      'endDate': endDate!,
    };
  }

  /// 解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    throw FormatException('无法解析日期: $dateStr');
  }

  /// 根据模式转换任务数据
  Map<String, dynamic> _convertTasksByMode(
    List<TimerTask> tasks,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildTasksSummary(tasks);
      case AnalysisMode.compact:
        return _buildTasksCompact(tasks);
      case AnalysisMode.full:
        return _buildTasksFull(tasks);
    }
  }

  /// 构建摘要数据
  Map<String, dynamic> _buildTasksSummary(List<TimerTask> tasks) {
    final runningTasks = tasks.where((t) => t.isRunning).length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalDuration = tasks
        .expand((t) => t.timerItems)
        .map((item) => item.duration.inSeconds)
        .fold<int>(0, (sum, dur) => sum + dur);

    return FieldUtils.buildSummaryResponse({
      'total': tasks.length,
      'running': runningTasks,
      'completed': completedTasks,
      'totalDuration': totalDuration,
    });
  }

  /// 构建紧凑数据
  Map<String, dynamic> _buildTasksCompact(List<TimerTask> tasks) {
    final summary = {
      'total': tasks.length,
      'running': tasks.where((t) => t.isRunning).length,
      'completed': tasks.where((t) => t.isCompleted).length,
    };

    final compactRecords = tasks.map((task) => _taskToCompactJson(task)).toList();

    return FieldUtils.buildCompactResponse(summary, compactRecords);
  }

  /// 构建完整数据
  Map<String, dynamic> _buildTasksFull(List<TimerTask> tasks) {
    final fullRecords = tasks.map((task) => _taskToFullJson(task)).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 任务转紧凑JSON
  Map<String, dynamic> _taskToCompactJson(TimerTask task) {
    return {
      'id': task.id,
      'name': task.name,
      'group': task.group,
      'isRunning': task.isRunning,
      'isCompleted': task.isCompleted,
      'created': FieldUtils.formatDateTime(task.createdAt),
      'timerCount': task.timerItems.length,
      'totalDuration': task.timerItems
          .map((item) => item.duration.inSeconds)
          .fold<int>(0, (sum, dur) => sum + dur),
      'elapsedDuration': task.elapsedDuration.inSeconds,
    };
  }

  /// 任务转完整JSON
  Map<String, dynamic> _taskToFullJson(TimerTask task) {
    return {
      'id': task.id,
      'name': task.name,
      'group': task.group,
      'color': task.color.toARGB32(),
      'icon': task.icon.codePoint,
      'isRunning': task.isRunning,
      'isCompleted': task.isCompleted,
      'createdAt': FieldUtils.formatDateTime(task.createdAt),
      'repeatCount': task.repeatCount,
      'remainingRepeatCount': task.remainingRepeatCount,
      'enableNotification': task.enableNotification,
      'elapsedDuration': task.elapsedDuration.inSeconds,
      'timerItems': task.timerItems.map((item) => _timerItemToJson(item)).toList(),
    };
  }

  /// 计时器项转JSON
  Map<String, dynamic> _timerItemToJson(TimerItem item) {
    final json = {
      'id': item.id,
      'name': item.name,
      'type': item.type.name,
      'duration': item.duration.inSeconds,
      'completedDuration': item.completedDuration.inSeconds,
      'remainingDuration': item.remainingDuration.inSeconds,
      'isRunning': item.isRunning,
      'isCompleted': item.isCompleted,
      'repeatCount': item.repeatCount,
      'enableNotification': item.enableNotification,
    };

    // 添加可选字段
    if (item.description != null) {
      json['description'] = item.description!;
    }

    // 番茄钟特有字段
    if (item.type == TimerType.pomodoro) {
      if (item.workDuration != null) {
        json['workDuration'] = item.workDuration!.inSeconds;
      }
      if (item.breakDuration != null) {
        json['breakDuration'] = item.breakDuration!.inSeconds;
      }
      if (item.cycles != null) {
        json['cycles'] = item.cycles!;
      }
      if (item.currentCycle != null) {
        json['currentCycle'] = item.currentCycle!;
      }
      if (item.isWorkPhase != null) {
        json['isWorkPhase'] = item.isWorkPhase!;
      }
    }

    return json;
  }

  /// 构建统计数据
  Map<String, dynamic> _buildStatistics(List<TimerTask> tasks, String groupBy) {
    switch (groupBy) {
      case 'day':
        return _buildDayStatistics(tasks);
      case 'task':
        return _buildTaskStatistics(tasks);
      case 'group':
        return _buildGroupStatistics(tasks);
      case 'type':
        return _buildTypeStatistics(tasks);
      default:
        return _buildDayStatistics(tasks);
    }
  }

  /// 按日期分组统计
  Map<String, dynamic> _buildDayStatistics(List<TimerTask> tasks) {
    final dayStats = <String, Map<String, dynamic>>{};

    for (final task in tasks) {
      final dateKey = '${task.createdAt.year}-${task.createdAt.month.toString().padLeft(2, '0')}-${task.createdAt.day.toString().padLeft(2, '0')}';

      if (!dayStats.containsKey(dateKey)) {
        dayStats[dateKey] = {
          'date': dateKey,
          'count': 0,
          'duration': 0,
        };
      }

      final stat = dayStats[dateKey]!;
      stat['count'] = (stat['count'] as int) + 1;

      final taskDuration = task.timerItems
          .map((item) => item.duration.inSeconds)
          .fold<int>(0, (sum, dur) => sum + dur);
      stat['duration'] = (stat['duration'] as int) + taskDuration;
    }

    return {
      'groupBy': 'day',
      'data': dayStats.values.toList(),
    };
  }

  /// 按任务分组统计
  Map<String, dynamic> _buildTaskStatistics(List<TimerTask> tasks) {
    return {
      'groupBy': 'task',
      'data': tasks.map((task) => {
        'id': task.id,
        'name': task.name,
        'timerCount': task.timerItems.length,
        'totalDuration': task.timerItems
            .map((item) => item.duration.inSeconds)
            .fold<int>(0, (sum, dur) => sum + dur),
        'completedDuration': task.timerItems
            .map((item) => item.completedDuration.inSeconds)
            .fold<int>(0, (sum, dur) => sum + dur),
      }).toList(),
    };
  }

  /// 按分组统计
  Map<String, dynamic> _buildGroupStatistics(List<TimerTask> tasks) {
    final groupStats = <String, Map<String, dynamic>>{};

    for (final task in tasks) {
      final groupName = task.group;

      if (!groupStats.containsKey(groupName)) {
        groupStats[groupName] = {
          'group': groupName,
          'count': 0,
          'duration': 0,
        };
      }

      final stat = groupStats[groupName]!;
      stat['count'] = (stat['count'] as int) + 1;

      final taskDuration = task.timerItems
          .map((item) => item.duration.inSeconds)
          .fold<int>(0, (sum, dur) => sum + dur);
      stat['duration'] = (stat['duration'] as int) + taskDuration;
    }

    return {
      'groupBy': 'group',
      'data': groupStats.values.toList(),
    };
  }

  /// 按类型统计
  Map<String, dynamic> _buildTypeStatistics(List<TimerTask> tasks) {
    final typeStats = <String, Map<String, dynamic>>{};

    for (final task in tasks) {
      for (final item in task.timerItems) {
        final typeName = item.type.name;

        if (!typeStats.containsKey(typeName)) {
          typeStats[typeName] = {
            'type': typeName,
            'count': 0,
            'duration': 0,
          };
        }

        final stat = typeStats[typeName]!;
        stat['count'] = (stat['count'] as int) + 1;
        stat['duration'] = (stat['duration'] as int) + item.duration.inSeconds;
      }
    }

    return {
      'groupBy': 'type',
      'data': typeStats.values.toList(),
    };
  }

  /// 释放资源
  void dispose() {}
}
