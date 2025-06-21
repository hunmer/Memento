import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import 'services/timer_service.dart';
import 'storage/timer_controller.dart';

class TimerPlugin extends BasePlugin {
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

  late final TimerController timerController;

  List<TimerTask> _tasks = [];
  @override
  String get id => 'timer';

  @override
  String get name => '计时器';

  @override
  String get description => '支持多种计时类型的任务管理器';

  @override
  IconData get icon => Icons.timer;

  @override
  Future<void> initialize() async {
    await _loadTasks();
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color ?? theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                name,
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
                      Text('总计时器', style: theme.textTheme.bodyMedium),
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
}
