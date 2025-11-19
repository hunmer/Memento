import 'package:flutter/material.dart';
import '../tracker_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Tracker插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class TrackerPromptReplacements {
  final TrackerPlugin _plugin;

  TrackerPromptReplacements(this._plugin);

  /// 获取目标数据并格式化为文本
  ///
  /// 参数:
  /// - status: 状态过滤 (可选, 'active'/'completed')
  /// - group: 分组过滤 (可选)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, active, avgProgress }, topGoals: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无imagePath等)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getGoals(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final status = params['status'] as String?;
      final group = params['group'] as String?;

      // 2. 获取目标列表
      List<Goal> goals;
      if (status != null && status.isNotEmpty) {
        goals = await _plugin.controller.getGoalsByStatus(status);
      } else {
        goals = await _plugin.controller.getAllGoals();
      }

      // 3. 应用分组过滤
      if (group != null && group.isNotEmpty) {
        goals = goals.where((g) => g.group == group).toList();
      }

      // 4. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final goalJsonList = goals.map((g) => g.toJson()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          goalJsonList,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(goals, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取目标数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取目标数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取目标进度数据
  ///
  /// 参数:
  /// - goalId: 目标ID (可选, 不提供则返回全局统计)
  ///
  /// 返回格式: { goalId, currentValue, targetValue, progress, percentage, isCompleted }
  Future<String> getProgress(Map<String, dynamic> params) async {
    try {
      final goalId = params['goalId'] as String?;

      if (goalId != null && goalId.isNotEmpty) {
        // 返回单个目标的进度
        final goals = await _plugin.controller.getAllGoals();
        final goal = goals.firstWhere(
          (g) => g.id == goalId,
          orElse: () => throw ArgumentError('目标不存在: $goalId'),
        );

        final progress = _plugin.controller.calculateProgress(goal);

        return FieldUtils.toJsonString({
          'goalId': goalId,
          'current': goal.currentValue,
          'target': goal.targetValue,
          'progress': progress,
          'percent': (progress * 100).toStringAsFixed(1),
          'completed': goal.isCompleted,
        });
      } else {
        // 返回全局进度统计
        final overallProgress = _plugin.controller.calculateOverallProgress();
        final totalGoals = _plugin.controller.getGoalCount();

        return FieldUtils.toJsonString({
          'totalGoals': totalGoals,
          'avgProgress': overallProgress,
          'avgPercent': (overallProgress * 100).toStringAsFixed(1),
          'todayCompleted': _plugin.controller.getTodayCompletedGoals(),
          'monthCompleted': _plugin.controller.getMonthCompletedGoals(),
        });
      }
    } catch (e) {
      debugPrint('获取进度数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取进度数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    List<Goal> goals,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(goals);
      case AnalysisMode.compact:
        return _buildCompact(goals);
      case AnalysisMode.full:
        return _buildFull(goals);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 10,
  ///     "active": 8,
  ///     "avgProgress": 0.65,
  ///     "topGoals": [{"name": "阅读", "progress": 0.8}]
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<Goal> goals) {
    if (goals.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'active': 0,
        'avgProgress': 0,
      });
    }

    final total = goals.length;
    final active = goals.where((g) => !g.isCompleted).length;

    // 计算平均进度
    double totalProgress = 0;
    for (final goal in goals) {
      totalProgress += _plugin.controller.calculateProgress(goal);
    }
    final avgProgress = totalProgress / goals.length;

    // 找出进度最高的5个目标
    final sortedGoals = List<Goal>.from(goals)
      ..sort((a, b) {
        final progressA = _plugin.controller.calculateProgress(a);
        final progressB = _plugin.controller.calculateProgress(b);
        return progressB.compareTo(progressA);
      });

    final topGoals = sortedGoals.take(5).map((g) {
      final progress = _plugin.controller.calculateProgress(g);
      return {
        'name': g.name,
        'progress': double.parse(progress.toStringAsFixed(2)),
        'unit': g.unitType,
      };
    }).toList();

    return FieldUtils.buildSummaryResponse({
      'total': total,
      'active': active,
      'avgProgress': double.parse(avgProgress.toStringAsFixed(2)),
      if (topGoals.isNotEmpty) 'topGoals': topGoals,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 10, "active": 8 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "name": "每日阅读",
  ///       "progress": 0.75,
  ///       "target": 30,
  ///       "unit": "分钟"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Goal> goals) {
    if (goals.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'active': 0},
        [],
      );
    }

    final active = goals.where((g) => !g.isCompleted).length;

    // 简化记录（移除 imagePath, progressColor 等字段）
    final compactRecords = goals.map((goal) {
      final progress = _plugin.controller.calculateProgress(goal);

      final record = <String, dynamic>{
        'id': goal.id,
        'name': goal.name,
        'progress': double.parse(progress.toStringAsFixed(2)),
        'target': goal.targetValue,
        'unit': goal.unitType,
      };

      // 只添加非空字段
      if (goal.group.isNotEmpty) {
        record['group'] = goal.group;
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': goals.length,
        'active': active,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<Goal> goals) {
    final goalJsonList = goals.map((g) => g.toJson()).toList();
    return FieldUtils.buildFullResponse(goalJsonList);
  }

  /// 释放资源
  void dispose() {}
}
