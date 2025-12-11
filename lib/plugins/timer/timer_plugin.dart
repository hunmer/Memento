import 'package:get/get.dart';
import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/core/services/timer/events/timer_events.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import 'services/timer_service.dart';
import 'storage/timer_controller.dart';

// UseCase 架构相关导入
import 'package:shared_models/usecases/timer/timer_usecase.dart';
import 'repositories/client_timer_repository.dart';

class TimerPlugin extends BasePlugin with JSBridgePlugin {
  late final TimerController timerController;

  // UseCase 架构
  late final TimerUseCase timerUseCase;
  late final ClientTimerRepository timerRepository;

  List<TimerTask> _tasks = [];
  static TimerPlugin? _instance;
  static TimerPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (_instance == null) {
        throw StateError('TimerPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'timer';

  @override
  Color get color => Colors.blueGrey;

  @override
  IconData get icon => Icons.timer;

  @override
  Future<void> initialize() async {
    // 1. 初始化统一计时器控制器
    await unifiedTimerController.initialize();

    // 2. 初始化存储控制器
    timerController = TimerController(storage);

    // 3. 初始化 UseCase 架构
    timerRepository = ClientTimerRepository(
      timerController: timerController,
      pluginColor: color,
    );
    timerUseCase = TimerUseCase(timerRepository);

    // 4. 加载任务数据
    await _loadTasks();

    // 5. 订阅统一计时器事件，转发给 TimerTask 事件系统
    _setupEventListeners();

    // 6. 恢复活动计时器状态
    await _restoreActiveTimers();

    // 7. 注册数据选择器
    _registerDataSelectors();

    // 8. 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return 'timer_name'.tr;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TimerMainView();
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    // 监听统一计时器事件，转发给现有事件系统
    EventManager.instance.subscribe(TimerEventNames.timerStarted, (args) {
      if (args is UnifiedTimerEventArgs) {
        final state = args.timerState as TimerState;
        // 转换为 TimerTask 并广播
        final task = _convertTimerStateToTimerTask(state);
        if (task != null) {
          EventManager.instance.broadcast(
            'timer_task_changed',
            TimerTaskEventArgs(task),
          );
        }
      }
    });

    EventManager.instance.subscribe(TimerEventNames.timerUpdated, (args) {
      if (args is UnifiedTimerEventArgs) {
        final state = args.timerState as TimerState;
        final task = _convertTimerStateToTimerTask(state);
        if (task != null) {
          EventManager.instance.broadcast(
            'timer_task_changed',
            TimerTaskEventArgs(task),
          );
        }
      }
    });

    EventManager.instance.subscribe(TimerEventNames.timerCompleted, (args) {
      if (args is UnifiedTimerEventArgs) {
        final state = args.timerState as TimerState;
        final task = _convertTimerStateToTimerTask(state);
        if (task != null) {
          // 广播计时器完成事件
          EventManager.instance.broadcast(
            'timer_item_changed',
            TimerItemEventArgs(task.activeTimer ?? task.timerItems.first),
          );
          EventManager.instance.broadcast(
            'timer_task_changed',
            TimerTaskEventArgs(task),
          );
        }
      }
    });
  }

  /// 恢复活动计时器状态
  Future<void> _restoreActiveTimers() async {
    // 从统一控制器获取活动计时器
    final activeTimers = unifiedTimerController.getActiveTimersByPlugin(
      'timer',
    );

    for (final timerState in activeTimers) {
      // 将统一状态转换回 TimerTask
      final task = _convertTimerStateToTimerTask(timerState);
      if (task != null && task.isRunning) {
        // 更新本地任务列表
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
        } else {
          _tasks.add(task);
        }
      }
    }
  }

  /// 将 TimerState 转换为 TimerTask
  TimerTask? _convertTimerStateToTimerTask(TimerState state) {
    // 查找现有任务
    final existingTask = _tasks.firstWhere(
      (t) => t.id == state.id,
      // ignore: cast_from_null_always_fails
      orElse: () => null as TimerTask,
    );

    if (existingTask != null) {
      // 更新运行状态和时长
      existingTask.isRunning = state.status == TimerStatus.running;
      existingTask.updateElapsedDuration(state.elapsed);
      return existingTask;
    }

    // 如果任务不存在，尝试从 JSON 重建
    return null;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'timer_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 总计时器数
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text(
                        'timer_totalTimer'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${_tasks.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取所有计时器任务
  List<TimerTask> getTasks() => _tasks;

  // 添加新任务
  Future<void> addTask(TimerTask task) async {
    _tasks.add(task);
    await saveTasks();
  }

  // 删除任务
  Future<void> removeTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await saveTasks();
  }

  // 更新任务
  Future<void> updateTask(TimerTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final oldTask = _tasks[index];
      _tasks[index] = task;

      if (!oldTask.isRunning && task.isRunning) {
        await startNotificationService(task);
      } else if (oldTask.isRunning && !task.isRunning) {
        await stopNotificationService(task.id);
      } else if (task.isRunning) {
        await _updateNotification(task);
      }
    }
  }

  // 启动前台通知服务
  Future<void> startNotificationService(TimerTask task) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await TimerService.startNotificationService(task);
    }
  }

  // 更新前台通知
  Future<void> _updateNotification(TimerTask task) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await TimerService.updateNotification(task);
    }
  }

  // 停止前台通知服务
  Future<void> stopNotificationService([String? id]) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await TimerService.stopNotificationService(id);
    }
  }

  // 从存储加载任务
  Future<void> _loadTasks() async {
    final data = await timerController.loadTasks();
    _tasks = data['tasks'] as List<TimerTask>;
    // 如果没有任何任务，添加默认示例任务
    if (_tasks.isEmpty) {
      _tasks.addAll(TimerController.createDefaultTasks());
      await saveTasks();
    }
  }

  // 保存任务到存储
  Future<void> saveTasks() async {
    await timerController.saveTasks(_tasks);
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位���（默认 0）
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

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 计时器列表
      'getTimers': _jsGetTimers,

      // 计时器管理
      'createTimer': _jsCreateTimer,
      'deleteTimer': _jsDeleteTimer,

      // 计时器控制
      'startTimer': _jsStartTimer,
      'pauseTimer': _jsPauseTimer,
      'stopTimer': _jsStopTimer,
      'resetTimer': _jsResetTimer,

      // 计时器状态
      'getTimerStatus': _jsGetTimerStatus,

      // 历史记录
      'getHistory': _jsGetHistory,

      // 查找方法
      'findTimerBy': _jsFindTimerBy,
      'findTimerById': _jsFindTimerById,
      'findTimerByName': _jsFindTimerByName,
      'findTimersByGroup': _jsFindTimersByGroup,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取计时器列表
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetTimers(Map<String, dynamic> params) async {
    final result = await timerUseCase.getTimerTasks(params);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return [];
    }

    // 如果是分页结果，转换格式
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final paginatedData = data as Map<String, dynamic>;
      final timerList = paginatedData['data'] as List<dynamic>;
      return {
        'data': timerList,
        'total': paginatedData['total'],
        'offset': paginatedData['offset'],
        'count': paginatedData['count'],
        'hasMore': paginatedData['hasMore'],
      };
    }

    // 非分页结果，直接返回列表
    return data;
  }

  /// 创建计时器
  Future<dynamic> _jsCreateTimer(Map<String, dynamic> params) async {
    final result = await timerUseCase.createTimerTask(params);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return {'error': '创建失败'};
    }

    return {
      'success': true,
      'id': data['id'],
      'message': '计时器创建成功',
    };
  }

  /// 删除计时器
  Future<dynamic> _jsDeleteTimer(Map<String, dynamic> params) async {
    // 转换参数名：timerId -> id
    final useCaseParams = {'id': params['timerId']};
    final result = await timerUseCase.deleteTimerTask(useCaseParams);

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

    // 查找任务并调用原始逻辑（这些操作涉及 UI 更新，不能简单通过 UseCase 处理）
    await timerController.loadTasks();
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.start();
    await updateTask(task);

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

    await timerController.loadTasks();
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.pause();
    await updateTask(task);

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

    await timerController.loadTasks();
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.pause();
    await stopNotificationService(task.id);
    await updateTask(task);

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

    await timerController.loadTasks();
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.reset();
    await updateTask(task);

    return {'success': true, 'message': '计时器已重置', 'id': task.id};
  }

  /// 获取计时器状态
  Future<dynamic> _jsGetTimerStatus(Map<String, dynamic> params) async {
    final String? timerId = params['timerId'];
    if (timerId == null || timerId.isEmpty) {
      return {'error': '缺少必需参数: timerId'};
    }

    // 转换参数名：timerId -> id
    final useCaseParams = {'id': timerId};
    final result = await timerUseCase.getTimerTaskById(useCaseParams);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return {'error': '计时器不存在'};
    }

    // 将 DTO 转换为原始格式返回
    final taskJson = data as Map<String, dynamic>;
    final timerItems = taskJson['timerItems'] as List<dynamic>;

    // 查找当前活动的计时器
    final activeTimerIndex = timerItems.indexWhere(
      (item) => item['isRunning'] == true,
    );
    final activeTimer = activeTimerIndex != -1 ? timerItems[activeTimerIndex] : null;

    return {
      'id': taskJson['id'],
      'name': taskJson['name'],
      'isRunning': taskJson['isRunning'],
      'repeatCount': taskJson['repeatCount'],
      'remainingRepeatCount': taskJson['repeatCount'], // DTO 中没有此字段，使用配置值
      'currentTimerIndex': activeTimerIndex,
      'activeTimer': activeTimer,
      'timerItems': timerItems,
    };
  }

  /// 获取计时历史
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetHistory(Map<String, dynamic> params) async {
    // UseCase 没有直接的获取历史方法，使用搜索功能查找已完成的任务
    final searchParams = {
      ...params,
      'isRunning': false, // 查找非运行状态的任务
    };

    final result = await timerUseCase.searchTimerTasks(searchParams);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return {'total': 0, 'tasks': []};
    }

    // 如果是分页结果，转换格式
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final paginatedData = data as Map<String, dynamic>;
      final taskList = paginatedData['data'] as List<dynamic>;

      // 过滤已完成的任务（这里简化处理，假设非运行状态就是已完成）
      final completedTasks = taskList.where((task) {
        final taskJson = task as Map<String, dynamic>;
        final timerItems = taskJson['timerItems'] as List<dynamic>;
        // 如果所有计时器都完成了，认为任务已完成
        return timerItems.every((item) => item['duration'] == item['completedDuration']);
      }).map((task) {
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
          'timerItems': timerItems.map((item) => {
            'name': item['name'],
            'type': _getTimerTypeName(item['type'] as int),
            'completedDuration': item['completedDuration'],
          }).toList(),
        };
      }).toList();

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
    final completedTasks = taskList.where((task) {
      final taskJson = task as Map<String, dynamic>;
      final timerItems = taskJson['timerItems'] as List<dynamic>;
      return timerItems.every((item) => item['duration'] == item['completedDuration']);
    }).map((task) {
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
        'timerItems': timerItems.map((item) => {
          'name': item['name'],
          'type': _getTimerTypeName(item['type'] as int),
          'completedDuration': item['completedDuration'],
        }).toList(),
      };
    }).toList();

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
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
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

    final result = await timerUseCase.searchTimerTasks(searchParams);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return findAll ? [] : null;
    }

    // 如果不是查找所有，只返回第一个匹配项
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
      final paginatedData = data as Map<String, dynamic>;
      final taskList = paginatedData['data'] as List<dynamic>;
      final matches = taskList.map((task) {
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

      // 如果有分页参数，返回分页格式
      final int? offset = params['offset'];
      final int? count = params['count'];
      if (offset != null || count != null) {
        final paginated = _paginate(
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
    final result = await timerUseCase.getTimerTaskById(useCaseParams);

    if (result.isFailure) {
      return null;
    }

    final data = result.dataOrNull;
    if (data == null) {
      return null;
    }

    final taskJson = data as Map<String, dynamic>;
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
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<dynamic> _jsFindTimerByName(Map<String, dynamic> params) async {
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return {'error': '缺少必需参数: name'};
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    // UseCase 没有按名称搜索的方法，我们先获取所有任务，然后在前端过滤
    final result = await timerUseCase.getTimerTasks({});

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return findAll ? [] : null;
    }

    final taskList = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

    final matches = <Map<String, dynamic>>[];

    for (final task in taskList) {
      final taskJson = task as Map<String, dynamic>;
      final taskName = taskJson['name'] as String;

      final isMatch = fuzzy
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
        final paginated = _paginate(
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
  /// @param params.count 分页返回数量 (可选，默认 100)
  Future<dynamic> _jsFindTimersByGroup(Map<String, dynamic> params) async {
    final String? group = params['group'];
    if (group == null || group.isEmpty) {
      return {'error': '缺少必需参数: group'};
    }

    // 使用 UseCase 的搜索功能
    final searchParams = {'group': group};
    final result = await timerUseCase.searchTimerTasks(searchParams);

    if (result.isFailure) {
      return {'error': result.errorOrNull?.message};
    }

    final data = result.dataOrNull;
    if (data == null) {
      return [];
    }

    final matches = <Map<String, dynamic>>[];

    // 转换格式
    final taskList = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

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
      final paginated = _paginate(
        matches,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return paginated;
    }

    return matches;
  }

  // ==================== 数据选择器注册 ====================

  /// 注册插件数据选择器
  void _registerDataSelectors() {
    // 注册计时任务选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'timer.task',
      pluginId: id,
      name: '选择计时任务',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'task',
          title: '选择计时任务',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return _tasks.map((task) {
              // 计算任务总时长
              final totalDuration = task.timerItems.fold<Duration>(
                Duration.zero,
                (sum, item) => sum + item.duration,
              );

              // 格式化时长显示
              String formatDuration(Duration duration) {
                final hours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);
                final seconds = duration.inSeconds.remainder(60);
                if (hours > 0) {
                  return '${hours}小时${minutes}分钟';
                } else if (minutes > 0) {
                  return '${minutes}分钟${seconds}秒';
                } else {
                  return '${seconds}秒';
                }
              }

              return SelectableItem(
                id: task.id,
                title: task.name,
                subtitle: '分组: ${task.group} · 时长: ${formatDuration(totalDuration)} · ${task.timerItems.length}个计时器',
                icon: task.icon,
                rawData: task,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final task = item.rawData as TimerTask;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  task.group.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
      ],
    ));
  }
}
