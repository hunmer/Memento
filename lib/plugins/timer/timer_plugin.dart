import 'package:get/get.dart';
import 'package:universal_platform/universal_platform.dart';

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

part 'timer_js_api.dart';
part 'timer_data_selectors.dart';

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
        // 只处理 timer 插件的计时器
        if (state.pluginId != 'timer') return;

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
        // 只处理 timer 插件的计时器
        if (state.pluginId != 'timer') return;

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
        // 只处理 timer 插件的计时器
        if (state.pluginId != 'timer') return;

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
    try {
      final existingTask = _tasks.firstWhere((t) => t.id == state.id);

      // 更新运行状态和时长
      existingTask.isRunning = state.status == TimerStatus.running;
      existingTask.updateElapsedDuration(state.elapsed);
      return existingTask;
    } catch (e) {
      // 任务不存在，返回 null
      return null;
    }
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
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      await TimerService.startNotificationService(task);
    }
  }

  // 更新前台通知
  Future<void> _updateNotification(TimerTask task) async {
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      await TimerService.updateNotification(task);
    }
  }

  // 停止前台通知服务
  Future<void> stopNotificationService([String? id]) async {
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
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
}
