part of 'tracker_plugin.dart';

// ==================== JS API 实现 ====================

/// 获取所有目标
/// 支持分页参数: offset, count
Future<dynamic> _jsGetGoals(Map<String, dynamic> params) async {
  // 提取可选参数
  final String? status = params['status'];
  final String? group = params['group'];

  // 构建参数（UseCase 不直接支持 group 筛选，需要在结果后处理）
  final useCaseParams = <String, dynamic>{
    if (status != null && status.isNotEmpty) 'status': status,
    if (params['offset'] != null) 'offset': params['offset'],
    if (params['count'] != null) 'count': params['count'],
  };

  final result = await _trackerUseCase.getGoals(useCaseParams);

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return jsonEncode({
      'success': false,
      'error': failure?.message ?? 'Unknown error',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  var goalsJson = result.dataOrNull;

  // 如果需要按分组筛选，在结果上处理
  if (group != null && group.isNotEmpty && goalsJson is List) {
    goalsJson = goalsJson.where((g) => g['group'] == group).toList();
  }

  // 如果有分页参数，UseCase 已经处理了分页
  // 如果没有分页参数，直接返回数据
  return jsonEncode({
    'success': true,
    'data': goalsJson ?? [],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

/// 获取单个目标详情
Future<dynamic> _jsGetGoal(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? goalId = params['goalId'];
  if (goalId == null || goalId.isEmpty) {
    return {'error': '缺少必需参数: goalId'};
  }

  final result = await _trackerUseCase.getGoalById({'id': goalId});

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'error': failure?.message ?? 'Unknown error'};
  }

  return result.dataOrNull;
}

/// 创建目标
Future<dynamic> _jsCreateGoal(Map<String, dynamic> params) async {
  // 转换参数格式以适配 UseCase
  final useCaseParams = <String, dynamic>{};

  // 提取必需参数
  if (params['name'] != null) useCaseParams['name'] = params['name'];
  if (params['icon'] != null) useCaseParams['icon'] = params['icon'];
  if (params['unitType'] != null) {
    useCaseParams['unitType'] = params['unitType'];
  }
  if (params['targetValue'] != null) {
    useCaseParams['targetValue'] = params['targetValue'];
  }

  // 提取可选参数
  if (params['id'] != null) useCaseParams['id'] = params['id'];
  if (params['group'] != null) useCaseParams['group'] = params['group'];
  if (params['iconColor'] != null) {
    useCaseParams['iconColor'] = params['iconColor'];
  }
  if (params['imagePath'] != null) {
    useCaseParams['imagePath'] = params['imagePath'];
  }
  if (params['progressColor'] != null) {
    useCaseParams['progressColor'] = params['progressColor'];
  }
  if (params['reminderTime'] != null) {
    useCaseParams['reminderTime'] = params['reminderTime'];
  }
  if (params['isLoopReset'] != null) {
    useCaseParams['isLoopReset'] = params['isLoopReset'];
  }

  // 处理日期设置
  final dateType = params['dateType'] ?? 'daily';
  useCaseParams['dateSettings'] = {
    'type': dateType,
    'startDate': params['startDate'],
    'endDate': params['endDate'],
    'selectedDays': params['selectedDays'],
    'monthDay': params['monthDay'],
  };

  final result = await _trackerUseCase.createGoal(useCaseParams);

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'error': failure?.message ?? 'Unknown error'};
  }

  return result.dataOrNull;
}

/// 更新目标
Future<dynamic> _jsUpdateGoal(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? goalId = params['goalId'];
  if (goalId == null || goalId.isEmpty) {
    return {'error': '缺少必需参数: goalId'};
  }

  // 转换参数格式以适配 UseCase
  final useCaseParams = <String, dynamic>{'id': goalId};

  // 从 updateJson 中提取所有可更新字段
  final updateJson = params['updateJson'] as Map<String, dynamic>? ?? {};

  // 添加所有可能的更新字段
  if (updateJson['name'] != null) useCaseParams['name'] = updateJson['name'];
  if (updateJson['icon'] != null) useCaseParams['icon'] = updateJson['icon'];
  if (updateJson['iconColor'] != null) {
    useCaseParams['iconColor'] = updateJson['iconColor'];
  }
  if (updateJson['unitType'] != null) {
    useCaseParams['unitType'] = updateJson['unitType'];
  }
  if (updateJson['targetValue'] != null) {
    useCaseParams['targetValue'] = updateJson['targetValue'];
  }
  if (updateJson['group'] != null) {
    useCaseParams['group'] = updateJson['group'];
  }
  if (updateJson['imagePath'] != null) {
    useCaseParams['imagePath'] = updateJson['imagePath'];
  }
  if (updateJson['progressColor'] != null) {
    useCaseParams['progressColor'] = updateJson['progressColor'];
  }
  if (updateJson['reminderTime'] != null) {
    useCaseParams['reminderTime'] = updateJson['reminderTime'];
  }
  if (updateJson['isLoopReset'] != null) {
    useCaseParams['isLoopReset'] = updateJson['isLoopReset'];
  }

  // 处理日期设置
  if (updateJson['dateSettings'] != null) {
    useCaseParams['dateSettings'] = updateJson['dateSettings'];
  }

  final result = await _trackerUseCase.updateGoal(useCaseParams);

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'error': failure?.message ?? 'Unknown error'};
  }

  return result.dataOrNull;
}

/// 删除目标
Future<dynamic> _jsDeleteGoal(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? goalId = params['goalId'];
  if (goalId == null || goalId.isEmpty) {
    return {'success': false, 'error': '缺少必需参数: goalId'};
  }

  final result = await _trackerUseCase.deleteGoal({'id': goalId});

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'success': false, 'error': failure?.message ?? 'Unknown error'};
  }

  final data = result.dataOrNull;
  return {'success': true, if (data != null) ...data};
}

/// 记录数据
Future<dynamic> _jsRecordData(Map<String, dynamic> params) async {
  // 转换参数格式以适配 UseCase
  final useCaseParams = <String, dynamic>{};

  // 提取必需参数
  if (params['goalId'] != null) useCaseParams['goalId'] = params['goalId'];
  if (params['value'] != null) useCaseParams['value'] = params['value'];

  // 提取可选参数
  if (params['id'] != null) useCaseParams['id'] = params['id'];
  if (params['note'] != null) useCaseParams['note'] = params['note'];
  if (params['durationSeconds'] != null) {
    useCaseParams['durationSeconds'] = params['durationSeconds'];
  }

  // 处理记录时间
  final dateTime = params['dateTime'];
  if (dateTime != null) {
    useCaseParams['recordedAt'] = dateTime;
  } else {
    useCaseParams['recordedAt'] = DateTime.now().toIso8601String();
  }

  final result = await _trackerUseCase.addRecord(useCaseParams);

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'error': failure?.message ?? 'Unknown error'};
  }

  return result.dataOrNull;
}

/// 获取目标的记录列表
/// 支持分页参数: offset, count
Future<dynamic> _jsGetRecords(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? goalId = params['goalId'];
  if (goalId == null || goalId.isEmpty) {
    return jsonEncode({
      'success': false,
      'error': '缺少必需参数: goalId',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // 构建参数（limit 参数不直接支持，需要在结果后处理）
  final useCaseParams = <String, dynamic>{
    'goalId': goalId,
    if (params['offset'] != null) 'offset': params['offset'],
    if (params['count'] != null) 'count': params['count'],
  };

  final result = await _trackerUseCase.getRecordsForGoal(useCaseParams);

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return jsonEncode({
      'success': false,
      'error': failure?.message ?? 'Unknown error',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  var recordsJson = result.dataOrNull;

  // 处理 limit 参数（向后兼容）
  final limit = params['limit'] as int?;
  if (limit != null && recordsJson is List && recordsJson.length > limit) {
    recordsJson = recordsJson.sublist(0, limit);
  }

  return jsonEncode({
    'success': true,
    'data': recordsJson ?? [],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

/// 删除记录
Future<dynamic> _jsDeleteRecord(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? recordId = params['recordId'];
  if (recordId == null || recordId.isEmpty) {
    return {'success': false, 'error': '缺少必需参数: recordId'};
  }

  final result = await _trackerUseCase.deleteRecord({'recordId': recordId});

  if (result.isFailure) {
    final failure = result.errorOrNull;
    return {'success': false, 'error': failure?.message ?? 'Unknown error'};
  }

  final data = result.dataOrNull;
  return {'success': true, if (data != null) ...data};
}

/// 获取目标进度
Future<dynamic> _jsGetProgress(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? goalId = params['goalId'];
  if (goalId == null || goalId.isEmpty) {
    return {'error': '缺少必需参数: goalId'};
  }

  // 先获取目标详情
  final goalResult = await _trackerUseCase.getGoalById({'id': goalId});

  if (goalResult.isFailure) {
    final failure = goalResult.errorOrNull;
    return {'error': failure?.message ?? 'Unknown error'};
  }

  final goalJson = goalResult.dataOrNull as Map<String, dynamic>;
  final currentValue = (goalJson['currentValue'] as num).toDouble();
  final targetValue = (goalJson['targetValue'] as num).toDouble();

  // 计算进度
  final progress =
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  return {
    'goalId': goalId,
    'currentValue': currentValue,
    'targetValue': targetValue,
    'progress': progress,
    'percentage': (progress * 100).toStringAsFixed(1),
    'isCompleted': currentValue >= targetValue,
  };
}

/// 获取统计信息
Future<dynamic> _jsGetStats(Map<String, dynamic> params) async {
  // 提取可选参数
  final String? goalId = params['goalId'];

  if (goalId != null && goalId.isNotEmpty) {
    // 返回单个目标的统计信息
    // 先获取目标详情
    final goalResult = await _trackerUseCase.getGoalById({'id': goalId});

    if (goalResult.isFailure) {
      final failure = goalResult.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    final goalJson = goalResult.dataOrNull as Map<String, dynamic>;

    // 获取记录列表
    final recordsResult = await _trackerUseCase.getRecordsForGoal({
      'goalId': goalId,
    });

    if (recordsResult.isFailure) {
      final failure = recordsResult.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    final records = recordsResult.dataOrNull as List;
    final totalValue = records.fold<double>(
      0.0,
      (sum, r) =>
          sum + ((r as Map<String, dynamic>)['value'] as num).toDouble(),
    );
    final currentValue = (goalJson['currentValue'] as num).toDouble();
    final targetValue = (goalJson['targetValue'] as num).toDouble();
    final progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return {
      'goalId': goalId,
      'goalName': goalJson['name'],
      'totalRecords': records.length,
      'totalValue': totalValue,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'progress': progress,
      'isCompleted': currentValue >= targetValue,
    };
  } else {
    // 返回全局统计信息
    final result = await _trackerUseCase.getStats({});

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    final stats = result.dataOrNull as Map<String, dynamic>;
    return stats;
  }
}
