part of 'habits_plugin.dart';

// JS API 实现 - 私有方法
// defineJSAPI() 方法在主插件类中实现

/// 获取所有习惯
/// 支持分页参数: offset, count
Future<String> _jsGetHabits(Map<String, dynamic> params) async {
  final result = await HabitsPlugin.instance._useCase.getHabits(params);

  return jsonEncode({
    'success': result.isSuccess,
    'data': result.dataOrNull ?? [],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'error': result.errorOrNull?.message,
  });
}

/// 根据ID获取习惯
Future<String> _jsGetHabitById(Map<String, dynamic> params) async {
  // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('habitId')) {
    useCaseParams['id'] = params['habitId'];
  }

  final result = await HabitsPlugin.instance._useCase.getHabitById(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull ?? {'error': 'Habit not found'});
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 创建习惯
Future<String> _jsCreateHabit(Map<String, dynamic> params) async {
  final result = await HabitsPlugin.instance._useCase.createHabit(params);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 更新习惯
Future<String> _jsUpdateHabit(Map<String, dynamic> params) async {
  // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('habitId')) {
    useCaseParams['id'] = params['habitId'];
  }

  final result = await HabitsPlugin.instance._useCase.updateHabit(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 删除习惯
Future<String> _jsDeleteHabit(Map<String, dynamic> params) async {
  // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('habitId')) {
    useCaseParams['id'] = params['habitId'];
  }

  final result = await HabitsPlugin.instance._useCase.deleteHabit(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode({'success': true});
  } else {
    return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
  }
}

/// 获取所有技能
/// 支持分页参数: offset, count
Future<String> _jsGetSkills(Map<String, dynamic> params) async {
  final result = await HabitsPlugin.instance._useCase.getSkills(params);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 根据ID获取技能
Future<String> _jsGetSkillById(Map<String, dynamic> params) async {
  // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('skillId')) {
    useCaseParams['id'] = params['skillId'];
  }

  final result = await HabitsPlugin.instance._useCase.getSkillById(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull ?? {'error': 'Skill not found'});
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 创建技能
Future<String> _jsCreateSkill(Map<String, dynamic> params) async {
  final result = await HabitsPlugin.instance._useCase.createSkill(params);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 更新技能
Future<String> _jsUpdateSkill(Map<String, dynamic> params) async {
  // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('skillId')) {
    useCaseParams['id'] = params['skillId'];
  }

  final result = await HabitsPlugin.instance._useCase.updateSkill(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 删除技能
Future<String> _jsDeleteSkill(Map<String, dynamic> params) async {
  // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('skillId')) {
    useCaseParams['id'] = params['skillId'];
  }

  final result = await HabitsPlugin.instance._useCase.deleteSkill(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode({'success': true});
  } else {
    return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
  }
}

/// 打卡（创建完成记录）
Future<String> _jsCheckIn(Map<String, dynamic> params) async {
  // 转换参数格式
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('habitId')) {
    useCaseParams['parentId'] = params['habitId'];
  }
  if (params.containsKey('durationSeconds')) {
    useCaseParams['durationSeconds'] = params['durationSeconds'];
  } else if (params.containsKey('durationMinutes')) {
    // 如果传入的是分钟，转换为秒
    useCaseParams['durationSeconds'] = (params['durationMinutes'] as int) * 60;
  }
  if (!useCaseParams.containsKey('date')) {
    useCaseParams['date'] = DateTime.now().toIso8601String();
  }

  final result = await HabitsPlugin.instance._useCase.createCompletionRecord(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 获取完成记录
/// 支持分页参数: offset, count
Future<String> _jsGetCompletionRecords(Map<String, dynamic> params) async {
  // 转换参数格式
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('habitId')) {
    useCaseParams['parentId'] = params['habitId'];
  }

  final result = await HabitsPlugin.instance._useCase.getCompletionRecords(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode(result.dataOrNull);
  } else {
    return jsonEncode({'error': result.errorOrNull?.message});
  }
}

/// 删除完成记录
Future<String> _jsDeleteCompletionRecord(Map<String, dynamic> params) async {
  // 转换参数格式
  final useCaseParams = Map<String, dynamic>.from(params);
  if (params.containsKey('recordId')) {
    useCaseParams['id'] = params['recordId'];
  }

  final result = await HabitsPlugin.instance._useCase.deleteCompletionRecord(useCaseParams);

  if (result.isSuccess) {
    return jsonEncode({'success': true});
  } else {
    return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
  }
}

/// 获取统计信息
Future<String> _jsGetStats(Map<String, dynamic> params) async {
  // 必需参数
  final String? habitId = params['habitId'];
  if (habitId == null) {
    return jsonEncode({'error': '缺少必需参数: habitId'});
  }

  // 获取总时长
  final durationParams = {'habitId': habitId};
  final durationResult = await HabitsPlugin.instance._useCase.getHabitTotalDuration(durationParams);

  // 获取完成次数
  final countParams = {'habitId': habitId};
  final countResult = await HabitsPlugin.instance._useCase.getHabitCompletionCount(countParams);

  if (durationResult.isSuccess && countResult.isSuccess) {
    return jsonEncode({
      'habitId': habitId,
      'totalDurationMinutes': durationResult.dataOrNull,
      'completionCount': countResult.dataOrNull,
    });
  } else {
    return jsonEncode({
      'error': durationResult.errorOrNull?.message ?? countResult.errorOrNull?.message,
    });
  }
}

/// 获取今日需要打卡的习惯
/// 支持分页参数: offset, count
Future<String> _jsGetTodayHabits(Map<String, dynamic> params) async {
  // 首先获取所有习惯
  final allHabitsResult = await HabitsPlugin.instance._useCase.getHabits({});

  if (allHabitsResult.isFailure) {
    return jsonEncode({'error': allHabitsResult.errorOrNull?.message});
  }

  final allHabits = allHabitsResult.dataOrNull as List;
  final today = DateTime.now().weekday % 7; // 转换为 0-6 (周日-周六)

  // 过滤出今日需要打卡的习惯
  final todayHabits = allHabits.where((habitJson) {
    final intervalDays = habitJson['intervalDays'] as int? ?? 0;
    final reminderDays = List<int>.from(habitJson['reminderDays'] ?? []);

    // 如果是每日习惯（intervalDays == 0）或包含今日的提醒日期
    return intervalDays == 0 || reminderDays.contains(today);
  }).toList();

  // 检查是否需要分页
  final int? offset = params['offset'];
  final int? count = params['count'];

  if (offset != null || count != null) {
    final paginated = _paginate(
      todayHabits,
      offset: offset ?? 0,
      count: count ?? 100,
    );
    return jsonEncode(paginated);
  }

  // 兼容旧版本：无分页参数时返回全部数据
  return jsonEncode(todayHabits);
}

/// 分页控制器 - 对列表进行分页处理
/// @param list 原始数据列表
/// @param offset 起始位置（默认 0）
/// @param count 返回数量（默认 100）
/// @return 分页后的数据，包含 data、total、offset、count、hasMore
Map<String, dynamic> _paginate<T>(
  List<T> list, {
  int offset = 0,
  int count = 100,
}) {
  final total = list.length;
  final start = offset.clamp(0, total);
  final end = (start + count).clamp(start, total);
  final data = list.sublist(start, end);

  return {
    'data': data,
    'total': total,
    'offset': start,
    'count': data.length,
    'hasMore': end < total,
  };
}

/// 启动计时器
Future<String> _jsStartTimer(Map<String, dynamic> params) async {
  // 必需参数
  final String? habitId = params['habitId'];
  if (habitId == null) {
    return jsonEncode({'error': '缺少必需参数: habitId'});
  }

  // 确保习惯数据已加载完成
  final habits = await HabitsPlugin.instance._habitController.loadHabits();
  try {
    final habit = habits.firstWhere((h) => h.id == habitId);

    // 启动计时器（使用空回调，因为 JS API 不需要实时更新）
    HabitsPlugin.instance._timerController.startTimer(
      habit,
      (elapsedSeconds) {}, // 空回调
    );

    return jsonEncode({
      'habitId': habitId,
      'status': 'started',
      'durationMinutes': habit.durationMinutes,
    });
  } catch (e) {
    return jsonEncode({'error': 'Habit not found: $habitId'});
  }
}

/// 停止计时器
Future<String> _jsStopTimer(Map<String, dynamic> params) async {
  // 必需参数
  final String? habitId = params['habitId'];
  if (habitId == null) {
    return jsonEncode({'error': '缺少必需参数: habitId'});
  }

  HabitsPlugin.instance._timerController.stopTimer(habitId);

  return jsonEncode({'habitId': habitId, 'status': 'stopped'});
}

/// 获取计时器状态
Future<String> _jsGetTimerStatus(Map<String, dynamic> params) async {
  // 必需参数
  final String? habitId = params['habitId'];
  if (habitId == null) {
    return jsonEncode({'error': '缺少必需参数: habitId'});
  }

  final timerData = HabitsPlugin.instance._timerController.getTimerData(habitId);
  final isRunning = HabitsPlugin.instance._timerController.isHabitTiming(habitId);

  if (timerData == null) {
    return jsonEncode({'habitId': habitId, 'isRunning': false});
  }

  return jsonEncode({
    'habitId': habitId,
    'isRunning': isRunning,
    'elapsedSeconds': timerData['elapsedSeconds'] ?? 0,
    'isCountdown': timerData['isCountdown'] ?? true,
  });
}
