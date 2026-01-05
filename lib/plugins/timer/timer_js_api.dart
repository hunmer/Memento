part of 'timer_plugin.dart';

// ==================== JS API 实现 ====================
// 以下函数供 TimerPlugin.defineJSAPI() 使用


/// 获取计时器列表
/// 支持分页参数: offset, count
Future<dynamic> _jsGetTimers(Map<String, dynamic> params) async {
  final result = await TimerPlugin.instance.timerUseCase.getTimerTasks(params);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return [];
  }

  // 如果是分页结果,转换格式
  if (data is Map<String, dynamic> && data.containsKey('data')) {
    final paginatedData = data;
    final timerList = paginatedData['data'] as List<dynamic>;
    return {
      'data': timerList,
      'total': paginatedData['total'],
      'offset': paginatedData['offset'],
      'count': paginatedData['count'],
      'hasMore': paginatedData['hasMore'],
    };
  }

  // 非分页结果,直接返回列表
  return data;
}

/// 创建计时器
Future<dynamic> _jsCreateTimer(Map<String, dynamic> params) async {
  final result = await TimerPlugin.instance.timerUseCase.createTimerTask(params);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return {'error': '创建失败'};
  }

  return {'success': true, 'id': data['id'], 'message': '计时器创建成功'};
}

/// 删除计时器
Future<dynamic> _jsDeleteTimer(Map<String, dynamic> params) async {
  // 转换参数名:timerId -> id
  final useCaseParams = {'id': params['timerId']};
  final result = await TimerPlugin.instance.timerUseCase.deleteTimerTask(useCaseParams);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  return {'success': true, 'message': '计时器已删除'};
}

/// 启动计时器
Future<dynamic> _jsStartTimer(Map<String, dynamic> params) async {
  final String? timerId = params['timerId'];
  if (timerId == null || timerId.isEmpty) {
    return {'error': '缺少必需参数: timerId'};
  }

  // 查找任务并调用原始逻辑(这些操作涉及 UI 更新,不能简单通过 UseCase 处理)
  await TimerPlugin.instance.timerController.loadTasks();
  final task = TimerPlugin.instance._tasks.firstWhere(
    (t) => t.id == timerId,
    orElse: () => throw Exception('计时器不存在'),
  );

  task.start();
  await TimerPlugin.instance.updateTask(task);

  return {
    'success': true,
    'message': '计时器已启动',
    'id': task.id,
    'isRunning': task.isRunning,
  };
}

/// 暂停计时器
Future<dynamic> _jsPauseTimer(Map<String, dynamic> params) async {
  final String? timerId = params['timerId'];
  if (timerId == null || timerId.isEmpty) {
    return {'error': '缺少必需参数: timerId'};
  }

  await TimerPlugin.instance.timerController.loadTasks();
  final task = TimerPlugin.instance._tasks.firstWhere(
    (t) => t.id == timerId,
    orElse: () => throw Exception('计时器不存在'),
  );

  task.pause();
  await TimerPlugin.instance.updateTask(task);

  return {
    'success': true,
    'message': '计时器已暂停',
    'id': task.id,
    'isRunning': task.isRunning,
  };
}

/// 停止计时器
Future<dynamic> _jsStopTimer(Map<String, dynamic> params) async {
  final String? timerId = params['timerId'];
  if (timerId == null || timerId.isEmpty) {
    return {'error': '缺少必需参数: timerId'};
  }

  await TimerPlugin.instance.timerController.loadTasks();
  final task = TimerPlugin.instance._tasks.firstWhere(
    (t) => t.id == timerId,
    orElse: () => throw Exception('计时器不存在'),
  );

  task.pause();
  await TimerPlugin.instance.stopNotificationService(task.id);
  await TimerPlugin.instance.updateTask(task);

  return {
    'success': true,
    'message': '计时器已停止',
    'id': task.id,
    'isRunning': task.isRunning,
  };
}

/// 重置计时器
Future<dynamic> _jsResetTimer(Map<String, dynamic> params) async {
  final String? timerId = params['timerId'];
  if (timerId == null || timerId.isEmpty) {
    return {'error': '缺少必需参数: timerId'};
  }

  await TimerPlugin.instance.timerController.loadTasks();
  final task = TimerPlugin.instance._tasks.firstWhere(
    (t) => t.id == timerId,
    orElse: () => throw Exception('计时器不存在'),
  );

  task.reset();
  await TimerPlugin.instance.updateTask(task);

  return {'success': true, 'message': '计时器已重置', 'id': task.id};
}

/// 获取计时器状态
Future<dynamic> _jsGetTimerStatus(Map<String, dynamic> params) async {
  final String? timerId = params['timerId'];
  if (timerId == null || timerId.isEmpty) {
    return {'error': '缺少必需参数: timerId'};
  }

  // 转换参数名:timerId -> id
  final useCaseParams = {'id': timerId};
  final result = await TimerPlugin.instance.timerUseCase.getTimerTaskById(useCaseParams);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return {'error': '计时器不存在'};
  }

  // 将 DTO 转换为原始格式返回
  final taskJson = data;
  final timerItems = taskJson['timerItems'] as List<dynamic>;

  // 查找当前活动的计时器
  final activeTimerIndex = timerItems.indexWhere(
    (item) => item['isRunning'] == true,
  );
  final activeTimer =
      activeTimerIndex != -1 ? timerItems[activeTimerIndex] : null;

  return {
    'id': taskJson['id'],
    'name': taskJson['name'],
    'isRunning': taskJson['isRunning'],
    'repeatCount': taskJson['repeatCount'],
    'remainingRepeatCount': taskJson['repeatCount'], // DTO 中没有此字段,使用配置值
    'currentTimerIndex': activeTimerIndex,
    'activeTimer': activeTimer,
    'timerItems': timerItems,
  };
}

/// 获取计时历史
/// 支持分页参数: offset, count
Future<dynamic> _jsGetHistory(Map<String, dynamic> params) async {
  // UseCase 没有直接的获取历史方法,使用搜索功能查找已完成的任务
  final searchParams = {
    ...params,
    'isRunning': false, // 查找非运行状态的任务
  };

  final result = await TimerPlugin.instance.timerUseCase.searchTimerTasks(searchParams);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return {'total': 0, 'tasks': []};
  }

  // 如果是分页结果,转换格式
  if (data is Map<String, dynamic> && data.containsKey('data')) {
    final paginatedData = data;
    final taskList = paginatedData['data'] as List<dynamic>;

    // 过滤已完成的任务(这里简化处理,假设非运行状态就是已完成)
    final completedTasks =
        taskList
            .where((task) {
              final taskJson = task as Map<String, dynamic>;
              final timerItems = taskJson['timerItems'] as List<dynamic>;
              // 如果所有计时器都完成了,认为任务已完成
              return timerItems.every(
                (item) => item['duration'] == item['completedDuration'],
              );
            })
            .map((task) {
              final taskJson = task as Map<String, dynamic>;
              final timerItems = taskJson['timerItems'] as List<dynamic>;
              final totalDuration = timerItems.fold<int>(
                0,
                (sum, item) => sum + (item['completedDuration'] as int),
              );

              return {
                'id': taskJson['id'],
                'name': taskJson['name'],
                'group': taskJson['group'],
                'createdAt': taskJson['createdAt'],
                'totalDuration': totalDuration,
                'timerItems':
                    timerItems
                        .map(
                          (item) => {
                            'name': item['name'],
                            'type': _getTimerTypeName(item['type'] as int),
                            'completedDuration': item['completedDuration'],
                          },
                        )
                        .toList(),
              };
            })
            .toList();

    return {
      'data': completedTasks,
      'total': paginatedData['total'],
      'offset': paginatedData['offset'],
      'count': paginatedData['count'],
      'hasMore': paginatedData['hasMore'],
    };
  }

  // 非分页结果
  final taskList = data as List<dynamic>;
  final completedTasks =
      taskList
          .where((task) {
            final taskJson = task as Map<String, dynamic>;
            final timerItems = taskJson['timerItems'] as List<dynamic>;
            return timerItems.every(
              (item) => item['duration'] == item['completedDuration'],
            );
          })
          .map((task) {
            final taskJson = task as Map<String, dynamic>;
            final timerItems = taskJson['timerItems'] as List<dynamic>;
            final totalDuration = timerItems.fold<int>(
              0,
              (sum, item) => sum + (item['completedDuration'] as int),
            );

            return {
              'id': taskJson['id'],
              'name': taskJson['name'],
              'group': taskJson['group'],
              'createdAt': taskJson['createdAt'],
              'totalDuration': totalDuration,
              'timerItems':
                  timerItems
                      .map(
                        (item) => {
                          'name': item['name'],
                          'type': _getTimerTypeName(item['type'] as int),
                          'completedDuration': item['completedDuration'],
                        },
                      )
                      .toList(),
            };
          })
          .toList();

  return {'total': completedTasks.length, 'tasks': completedTasks};
}

/// 获取计时器类型名称
String _getTimerTypeName(int typeIndex) {
  switch (typeIndex) {
    case 0:
      return 'countUp';
    case 1:
      return 'countDown';
    case 2:
      return 'pomodoro';
    default:
      return 'countUp';
  }
}

// ==================== 查找方法 ====================

/// 通用计时器查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.findAll 是否返回所有匹配项 (可选,默认 false)
/// @param params.offset 分页起始位置 (可选,仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选,仅 findAll=true 时有效,默认 100)
Future<dynamic> _jsFindTimerBy(Map<String, dynamic> params) async {
  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return {'error': '缺少必需参数: field'};
  }

  final dynamic value = params['value'];
  if (value == null) {
    return {'error': '缺少必需参数: value'};
  }

  final bool findAll = params['findAll'] ?? false;

  // 根据字段构建搜索参数
  Map<String, dynamic> searchParams = {};
  if (field.toLowerCase() == 'group') {
    searchParams['group'] = value;
  } else if (field.toLowerCase() == 'isRunning') {
    searchParams['isRunning'] = value;
  }

  final result = await TimerPlugin.instance.timerUseCase.searchTimerTasks(searchParams);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return findAll ? [] : null;
  }

  // 如果不是查找所有,只返回第一个匹配项
  if (!findAll && data is List && data.isNotEmpty) {
    final task = data.first as Map<String, dynamic>;
    return {
      'id': task['id'],
      'name': task['name'],
      'color': task['color'],
      'icon': task['iconCodePoint'],
      'group': task['group'],
      'isRunning': task['isRunning'],
      'repeatCount': task['repeatCount'],
    };
  }

  // 查找所有
  if (data is Map<String, dynamic> && data.containsKey('data')) {
    final paginatedData = data;
    final taskList = paginatedData['data'] as List<dynamic>;
    final matches =
        taskList.map((task) {
          final taskJson = task as Map<String, dynamic>;
          return {
            'id': taskJson['id'],
            'name': taskJson['name'],
            'color': taskJson['color'],
            'icon': taskJson['iconCodePoint'],
            'group': taskJson['group'],
            'isRunning': taskJson['isRunning'],
            'repeatCount': taskJson['repeatCount'],
          };
        }).toList();

    // 如果有分页参数,返回分页格式
    final int? offset = params['offset'];
    final int? count = params['count'];
    if (offset != null || count != null) {
      final paginated = TimerPlugin.instance._paginate(
        matches,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return paginated;
    }

    return matches;
  }

  return data;
}

/// 根据ID查找计时器
Future<dynamic> _jsFindTimerById(Map<String, dynamic> params) async {
  final String? id = params['id'];
  if (id == null || id.isEmpty) {
    return {'error': '缺少必需参数: id'};
  }

  final useCaseParams = {'id': id};
  final result = await TimerPlugin.instance.timerUseCase.getTimerTaskById(useCaseParams);

  if (result.isFailure) {
    return null;
  }

  final data = result.dataOrNull;
  if (data == null) {
    return null;
  }

  final taskJson = data;
  return {
    'id': taskJson['id'],
    'name': taskJson['name'],
    'color': taskJson['color'],
    'icon': taskJson['iconCodePoint'],
    'group': taskJson['group'],
    'isRunning': taskJson['isRunning'],
    'repeatCount': taskJson['repeatCount'],
    'remainingRepeatCount': taskJson['repeatCount'],
    'createdAt': taskJson['createdAt'],
  };
}

/// 根据名称查找计时器
/// @param params.name 计时器名称 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选,默认 false)
/// @param params.findAll 是否返回所有匹配项 (可选,默认 false)
/// @param params.offset 分页起始位置 (可选,仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选,仅 findAll=true 时有效,默认 100)
Future<dynamic> _jsFindTimerByName(Map<String, dynamic> params) async {
  final String? name = params['name'];
  if (name == null || name.isEmpty) {
    return {'error': '缺少必需参数: name'};
  }

  final bool fuzzy = params['fuzzy'] ?? false;
  final bool findAll = params['findAll'] ?? false;

  // UseCase 没有按名称搜索的方法,我们先获取所有任务,然后在前端过滤
  final result = await TimerPlugin.instance.timerUseCase.getTimerTasks({});

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return findAll ? [] : null;
  }

  final taskList =
      data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

  final matches = <Map<String, dynamic>>[];

  for (final task in taskList) {
    final taskJson = task as Map<String, dynamic>;
    final taskName = taskJson['name'] as String;

    final isMatch =
        fuzzy
            ? taskName.toLowerCase().contains(name.toLowerCase())
            : taskName == name;

    if (isMatch) {
      final taskData = {
        'id': taskJson['id'],
        'name': taskJson['name'],
        'color': taskJson['color'],
        'icon': taskJson['iconCodePoint'],
        'group': taskJson['group'],
        'isRunning': taskJson['isRunning'],
      };

      if (!findAll) {
        return taskData;
      }
      matches.add(taskData);
    }
  }

  if (findAll) {
    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];
    if (offset != null || count != null) {
      final paginated = TimerPlugin.instance._paginate(
        matches,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return paginated;
    }

    return matches;
  }

  return null;
}

/// 根据分组查找计时器
/// @param params.group 分组名称 (必需)
/// @param params.offset 分页起始位置 (可选)
/// @param params.count 分页返回数量 (可选,默认 100)
Future<dynamic> _jsFindTimersByGroup(Map<String, dynamic> params) async {
  final String? group = params['group'];
  if (group == null || group.isEmpty) {
    return {'error': '缺少必需参数: group'};
  }

  // 使用 UseCase 的搜索功能
  final searchParams = {'group': group};
  final result = await TimerPlugin.instance.timerUseCase.searchTimerTasks(searchParams);

  if (result.isFailure) {
    return {'error': result.errorOrNull?.message};
  }

  final data = result.dataOrNull;
  if (data == null) {
    return [];
  }

  final matches = <Map<String, dynamic>>[];

  // 转换格式
  final taskList =
      data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

  for (final task in taskList) {
    final taskJson = task as Map<String, dynamic>;
    matches.add({
      'id': taskJson['id'],
      'name': taskJson['name'],
      'color': taskJson['color'],
      'icon': taskJson['iconCodePoint'],
      'group': taskJson['group'],
      'isRunning': taskJson['isRunning'],
    });
  }

  // 检查是否需要分页
  final int? offset = params['offset'];
  final int? count = params['count'];
  if (offset != null || count != null) {
    final paginated = TimerPlugin.instance._paginate(
      matches,
      offset: offset ?? 0,
      count: count ?? 100,
    );
    return paginated;
  }

  return matches;
}
