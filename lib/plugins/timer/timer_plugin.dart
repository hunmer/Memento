import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import 'services/timer_service.dart';
import 'managers/timer_group_manager.dart';
import 'storage/timer_storage.dart';

class TimerPlugin extends BasePlugin {
  static final TimerPlugin instance = TimerPlugin._internal();
  late final TimerGroupManager _groupManager;
  late final TimerStorage _storage;

  TimerPlugin._internal() {
    _groupManager = TimerGroupManager(_tasks, _expandedGroups);
    _storage = TimerStorage(_id, storage);
  }

  static const String _id = 'timer';
  static const String _name = '计时器';
  static const String _version = '1.0.0';
  static const String _description = '支持多种计时类型的任务管理器';
  static const String _author = 'Zulu';
  static const String _pluginDir = 'timer';

  List<TimerTask> _tasks = [];
  Map<String, bool> _expandedGroups = {};

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get version => _version;

  @override
  String get description => _description;

  @override
  String get author => _author;

  @override
  String get pluginDir => _pluginDir;

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
    return TimerMainView(plugin: this);
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final runningTasks = _tasks.where((task) => task.isRunning).toList();
    final runningTaskNames = runningTasks.map((task) => task.name).join('、');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 总计时器数
              Column(
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

              // 当前运行中的计时器
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('当前运行', style: theme.textTheme.bodyMedium),
                  Text(
                    runningTasks.isEmpty ? '无' : runningTaskNames,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          runningTasks.isNotEmpty
                              ? theme.colorScheme.primary
                              : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 获取所有计时器任务
  List<TimerTask> getTasks() => _tasks;

  // 获取分组列表
  List<String> get groups => _groupManager.groups;

  // 获取分组展开状态
  Map<String, bool> get expandedGroups => _groupManager.expandedGroups;

  // 切换分组展开状态
  void toggleGroupExpansion(String group) {
    _groupManager.toggleGroupExpansion(group);
  }

  // 添加新任务
  Future<void> addTask(TimerTask task) async {
    _tasks.add(task);
    await _saveTasks();
  }

  // 删除任务
  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks();
  }

  // 更新任务
  Future<void> updateTask(TimerTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final oldTask = _tasks[index];
      _tasks[index] = task;
      await _saveTasks();

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
    await TimerService.startNotificationService(task);
  }

  // 更新前台通知
  Future<void> _updateNotification(TimerTask task) async {
    await TimerService.updateNotification(task);
  }

  // 停止前台通知服务
  Future<void> stopNotificationService([String? taskId]) async {
    await TimerService.stopNotificationService(taskId);
  }

  // 从存储加载任务
  Future<void> _loadTasks() async {
    final data = await _storage.loadTasks();
    _tasks = data['tasks'] as List<TimerTask>;
    _expandedGroups = data['expandedGroups'] as Map<String, bool>;

    // 如果没有任何任务，添加默认示例任务
    if (_tasks.isEmpty) {
      _tasks.addAll(TimerStorage.createDefaultTasks());
      await _saveTasks();
    }
  }

  // 保存任务到存储
  Future<void> _saveTasks() async {
    await _storage.saveTasks(_tasks, _expandedGroups);
  }

  // 显示分组管理对话框
  void showGroupManagementDialog(BuildContext context) {
    _groupManager.showGroupManagementDialog(context);
    _saveTasks();
  }
}
