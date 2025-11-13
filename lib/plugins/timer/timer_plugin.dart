import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import 'services/timer_service.dart';
import 'storage/timer_controller.dart';
import 'l10n/timer_localizations.dart';

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
    timerController = TimerController(storage);
    await _loadTasks();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return TimerLocalizations.of(context).name;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TimerMainView();
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
                TimerLocalizations.of(context).name,
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
                        TimerLocalizations.of(context).totalTimer,
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
  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
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
  Future<void> stopNotificationService([String? taskId]) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await TimerService.stopNotificationService(taskId);
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
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取计时器列表
  Future<String> _jsGetTimers() async {
    final timers = _tasks.map((task) => {
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
      'timerItems': task.timerItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'type': item.type.name,
        'duration': item.duration.inSeconds,
        'completedDuration': item.completedDuration.inSeconds,
        'isRunning': item.isRunning,
        'isCompleted': item.isCompleted,
        'remainingDuration': item.remainingDuration.inSeconds,
        'repeatCount': item.repeatCount,
        'enableNotification': item.enableNotification,
      }).toList(),
    }).toList();

    return jsonEncode(timers);
  }

  /// 创建计时器
  /// 参数: name(String), duration(int秒), type(String: countUp/countDown/pomodoro), group(String)
  Future<String> _jsCreateTimer(String name, int durationSeconds, String type, [String? group]) async {
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: timerType,
      duration: Duration(seconds: durationSeconds),
      completedDuration: Duration.zero,
      repeatCount: 1,
      enableNotification: false,
    );

    // 创建任务
    final task = TimerTask.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: Colors.blueGrey,
      icon: Icons.timer,
      timerItems: [timerItem],
      group: group ?? '默认',
      repeatCount: 1,
      enableNotification: false,
    );

    await addTask(task);

    return jsonEncode({
      'success': true,
      'taskId': task.id,
      'message': '计时器创建成功',
    });
  }

  /// 删除计时器
  /// 参数: timerId(String)
  Future<String> _jsDeleteTimer(String timerId) async {
    await removeTask(timerId);

    return jsonEncode({
      'success': true,
      'message': '计时器已删除',
    });
  }

  /// 启动计时器
  /// 参数: timerId(String)
  Future<String> _jsStartTimer(String timerId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.start();
    await updateTask(task);

    return jsonEncode({
      'success': true,
      'message': '计时器已启动',
      'taskId': task.id,
      'isRunning': task.isRunning,
    });
  }

  /// 暂停计时器
  /// 参数: timerId(String)
  Future<String> _jsPauseTimer(String timerId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.pause();
    await updateTask(task);

    return jsonEncode({
      'success': true,
      'message': '计时器已暂停',
      'taskId': task.id,
      'isRunning': task.isRunning,
    });
  }

  /// 停止计时器
  /// 参数: timerId(String)
  Future<String> _jsStopTimer(String timerId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.pause();
    await stopNotificationService(task.id);
    await updateTask(task);

    return jsonEncode({
      'success': true,
      'message': '计时器已停止',
      'taskId': task.id,
      'isRunning': task.isRunning,
    });
  }

  /// 重置计时器
  /// 参数: timerId(String)
  Future<String> _jsResetTimer(String timerId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    task.reset();
    await updateTask(task);

    return jsonEncode({
      'success': true,
      'message': '计时器已重置',
      'taskId': task.id,
    });
  }

  /// 获取计时器状态
  /// 参数: timerId(String)
  Future<String> _jsGetTimerStatus(String timerId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('计时器不存在'),
    );

    final activeTimer = task.activeTimer;
    final currentIndex = task.getCurrentIndex();

    return jsonEncode({
      'taskId': task.id,
      'name': task.name,
      'isRunning': task.isRunning,
      'isCompleted': task.isCompleted,
      'elapsedDuration': task.elapsedDuration.inSeconds,
      'repeatCount': task.repeatCount,
      'remainingRepeatCount': task.remainingRepeatCount,
      'currentTimerIndex': currentIndex,
      'activeTimer': activeTimer != null ? {
        'id': activeTimer.id,
        'name': activeTimer.name,
        'type': activeTimer.type.name,
        'duration': activeTimer.duration.inSeconds,
        'completedDuration': activeTimer.completedDuration.inSeconds,
        'remainingDuration': activeTimer.remainingDuration.inSeconds,
        'isRunning': activeTimer.isRunning,
        'isCompleted': activeTimer.isCompleted,
        'formattedRemainingTime': activeTimer.formattedRemainingTime,
      } : null,
      'timerItems': task.timerItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'type': item.type.name,
        'duration': item.duration.inSeconds,
        'completedDuration': item.completedDuration.inSeconds,
        'remainingDuration': item.remainingDuration.inSeconds,
        'isCompleted': item.isCompleted,
      }).toList(),
    });
  }

  /// 获取计时历史
  /// 返回所有已完成的计时器任务
  Future<String> _jsGetHistory() async {
    final completedTasks = _tasks.where((task) => task.isCompleted).map((task) => {
      'id': task.id,
      'name': task.name,
      'group': task.group,
      'createdAt': task.createdAt.toIso8601String(),
      'totalDuration': task.timerItems
          .map((item) => item.completedDuration.inSeconds)
          .fold<int>(0, (sum, duration) => sum + duration),
      'timerItems': task.timerItems.map((item) => {
        'name': item.name,
        'type': item.type.name,
        'completedDuration': item.completedDuration.inSeconds,
      }).toList(),
    }).toList();

    return jsonEncode({
      'total': completedTasks.length,
      'tasks': completedTasks,
    });
  }
}
