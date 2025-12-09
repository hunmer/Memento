import 'package:get/get.dart';
import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/core/services/timer/events/timer_events.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import 'services/timer_service.dart';
import 'storage/timer_controller.dart';

class TimerPlugin extends BasePlugin with JSBridgePlugin {
  late final TimerController timerController;

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

    timerController = TimerController(storage);
    await _loadTasks();

    // 2. 订阅统一计时器事件，转发给 TimerTask 事件系统
    _setupEventListeners();

    // 3. 恢复活动计时器状态
    await _restoreActiveTimers();

    // 注册 JS API（最后一步）
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
    final timers =
        _tasks
            .map(
              (task) => {
                'id': task.id,
                'name': task.name,
                'color': task.color.toARGB32(),
                'icon': task.icon.codePoint,
                'group': task.group,
                'isRunning': task.isRunning,
                'repeatCount': task.repeatCount,
                'remainingRepeatCount': task.remainingRepeatCount,
                'enableNotification': task.enableNotification,
                'createdAt': task.createdAt.toIso8601String(),
                'timerItems':
                    task.timerItems
                        .map(
                          (item) => {
                            'id': item.id,
                            'name': item.name,
                            'description': item.description,
                            'type': item.type.name,
                            'duration': item.duration.inSeconds,
                            'completedDuration':
                                item.completedDuration.inSeconds,
                            'isRunning': item.isRunning,
                            'isCompleted': item.isCompleted,
                            'remainingDuration':
                                item.remainingDuration.inSeconds,
                            'repeatCount': item.repeatCount,
                            'enableNotification': item.enableNotification,
                          },
                        )
                        .toList(),
              },
            )
            .toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        timers,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return paginated;
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return timers;
  }

  /// 创建计时器
  Future<dynamic> _jsCreateTimer(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return {'error': '缺少必需参数: name'};
    }

    final int? durationSeconds = params['duration'];
    if (durationSeconds == null) {
      return {'error': '缺少必需参数: duration'};
    }

    final String? type = params['type'];
    if (type == null || type.isEmpty) {
      return {'error': '缺少必需参数: type'};
    }

    // 提取可选参数
    final String? group = params['group'];
    final String? customId = params['id'];

    // 如果提供了自定义ID，检查是否已存在
    String id;
    if (customId != null && customId.isNotEmpty) {
      // 检查ID是否已存在
      final existingTask = _tasks.firstWhere(
        (t) => t.id == customId,
        orElse:
            () => TimerTask.create(
              id: '',
              name: '',
              color: Colors.transparent,
              icon: Icons.error,
              timerItems: [],
            ),
      );

      if (existingTask.id.isNotEmpty) {
        return {'error': '计时器ID已存在: $customId'};
      }

      id = customId;
    } else {
      // 使用UUID生成
      id = const Uuid().v4();
    }

    // 解析计时器类型
    TimerType timerType;
    try {
      timerType = TimerType.values.firstWhere(
        (t) => t.name == type.toLowerCase(),
        orElse: () => TimerType.countUp,
      );
    } catch (e) {
      timerType = TimerType.countUp;
    }

    // 创建计时器项
    final timerItem = TimerItem(
      id: const Uuid().v4(),
      name: name,
      type: timerType,
      duration: Duration(seconds: durationSeconds),
      completedDuration: Duration.zero,
      repeatCount: 1,
      enableNotification: false,
    );

    // 创建任务
    final task = TimerTask.create(
      id: id,
      name: name,
      color: Colors.blueGrey,
      icon: Icons.timer,
      timerItems: [timerItem],
      group: group ?? '默认',
      repeatCount: 1,
      enableNotification: false,
    );

    await addTask(task);

    return {'success': true, 'id': task.id, 'message': '计时器创建成功'};
  }

  /// 删除计时器
  Future<dynamic> _jsDeleteTimer(Map<String, dynamic> params) async {
    final String? timerId = params['timerId'];
    if (timerId == null || timerId.isEmpty) {
      return {'error': '缺少必需参数: timerId'};
    }

    await removeTask(timerId);

    return {'success': true, 'message': '计时器已删除'};
  }

  /// 启动计时器
  Future<dynamic> _jsStartTimer(Map<String, dynamic> params) async {
    final String? timerId = params['timerId'];
    if (timerId == null || timerId.isEmpty) {
      return {'error': '缺少必需参数: timerId'};
    }

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

    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    final activeTimer = task.activeTimer;
    final currentIndex = task.getCurrentIndex();

    return {
      'id': task.id,
      'name': task.name,
      'isRunning': task.isRunning,
      'isCompleted': task.isCompleted,
      'elapsedDuration': task.elapsedDuration.inSeconds,
      'repeatCount': task.repeatCount,
      'remainingRepeatCount': task.remainingRepeatCount,
      'currentTimerIndex': currentIndex,
      'activeTimer':
          activeTimer != null
              ? {
                'id': activeTimer.id,
                'name': activeTimer.name,
                'type': activeTimer.type.name,
                'duration': activeTimer.duration.inSeconds,
                'completedDuration': activeTimer.completedDuration.inSeconds,
                'remainingDuration': activeTimer.remainingDuration.inSeconds,
                'isRunning': activeTimer.isRunning,
                'isCompleted': activeTimer.isCompleted,
                'formattedRemainingTime': activeTimer.formattedRemainingTime,
              }
              : null,
      'timerItems':
          task.timerItems
              .map(
                (item) => {
                  'id': item.id,
                  'name': item.name,
                  'type': item.type.name,
                  'duration': item.duration.inSeconds,
                  'completedDuration': item.completedDuration.inSeconds,
                  'remainingDuration': item.remainingDuration.inSeconds,
                  'isCompleted': item.isCompleted,
                },
              )
              .toList(),
    };
  }

  /// 获取计时历史
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetHistory(Map<String, dynamic> params) async {
    final completedTasks =
        _tasks
            .where((task) => task.isCompleted)
            .map(
              (task) => {
                'id': task.id,
                'name': task.name,
                'group': task.group,
                'createdAt': task.createdAt.toIso8601String(),
                'totalDuration': task.timerItems
                    .map((item) => item.completedDuration.inSeconds)
                    .fold<int>(0, (sum, duration) => sum + duration),
                'timerItems':
                    task.timerItems
                        .map(
                          (item) => {
                            'name': item.name,
                            'type': item.type.name,
                            'completedDuration':
                                item.completedDuration.inSeconds,
                          },
                        )
                        .toList(),
              },
            )
            .toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        completedTasks,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return {
        'data': paginated['data'],
        'total': paginated['total'],
        'offset': paginated['offset'],
        'count': paginated['count'],
        'hasMore': paginated['hasMore'],
      };
    }

    // 兼容旧版本：无分页参数时返回原格式
    return {'total': completedTasks.length, 'tasks': completedTasks};
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
    final int? offset = params['offset'];
    final int? count = params['count'];

    final matches = <Map<String, dynamic>>[];

    for (var task in _tasks) {
      bool isMatch = false;

      switch (field.toLowerCase()) {
        case 'id':
          isMatch = task.id == value;
          break;
        case 'name':
          isMatch = task.name == value;
          break;
        case 'group':
          isMatch = task.group == value;
          break;
        default:
          isMatch = false;
      }

      if (isMatch) {
        final taskData = {
          'id': task.id,
          'name': task.name,
          'color': task.color.toARGB32(),
          'icon': task.icon.codePoint,
          'group': task.group,
          'isRunning': task.isRunning,
          'repeatCount': task.repeatCount,
        };

        if (!findAll) {
          return taskData;
        }
        matches.add(taskData);
      }
    }

    if (findAll) {
      // 检查是否需要分页
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

  /// 根据ID查找计时器
  Future<dynamic> _jsFindTimerById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return {'error': '缺少必需参数: id'};
    }

    try {
      final task = _tasks.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('计时器不存在'),
      );

      return {
        'id': task.id,
        'name': task.name,
        'color': task.color.toARGB32(),
        'icon': task.icon.codePoint,
        'group': task.group,
        'isRunning': task.isRunning,
        'repeatCount': task.repeatCount,
        'remainingRepeatCount': task.remainingRepeatCount,
        'createdAt': task.createdAt.toIso8601String(),
      };
    } catch (e) {
      return null;
    }
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
    final int? offset = params['offset'];
    final int? count = params['count'];

    final matches = <Map<String, dynamic>>[];

    for (var task in _tasks) {
      final isMatch =
          fuzzy
              ? task.name.toLowerCase().contains(name.toLowerCase())
              : task.name == name;

      if (isMatch) {
        final taskData = {
          'id': task.id,
          'name': task.name,
          'color': task.color.toARGB32(),
          'icon': task.icon.codePoint,
          'group': task.group,
          'isRunning': task.isRunning,
        };

        if (!findAll) {
          return taskData;
        }
        matches.add(taskData);
      }
    }

    if (findAll) {
      // 检查是否需要分页
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

    final int? offset = params['offset'];
    final int? count = params['count'];

    final matches =
        _tasks
            .where((task) => task.group == group)
            .map(
              (task) => {
                'id': task.id,
                'name': task.name,
                'color': task.color.toARGB32(),
                'icon': task.icon.codePoint,
                'group': task.group,
                'isRunning': task.isRunning,
              },
            )
            .toList();

    // 检查是否需要分页
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
}
