import 'dart:convert';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import 'controllers/controllers.dart';
import 'models/models.dart';
import 'views/todo_main_view.dart';
import 'controls/prompt_controller.dart';

class TodoPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  late TaskController taskController;
  late ReminderController reminderController;
  late TodoPromptController _promptController;
  static TodoPlugin? _instance;
  static TodoPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (_instance == null) {
        throw StateError('TodoPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'todo';

  @override
  IconData get icon => Icons.check_box;

  @override
  Color get color => Colors.blue;

  @override
  String? getPluginName(context) {
    return TodoLocalizations.of(context).name;
  }

  @override
  Future<void> initialize() async {
    taskController = TaskController(storageManager, storageDir);
    reminderController = ReminderController();

    // 加载默认设置
    await loadSettings({
      'defaultView': 'list', // 'list' or 'grid'
      'defaultSortBy': 'dueDate', // 'dueDate', 'priority', or 'custom'
      'reminderAdvanceTime': 60, // minutes
    });

    // 初始化 Prompt 控制器
    _promptController = TodoPromptController(this);
    _promptController.initialize();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件相关服务
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TodoMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = taskController.getTotalTaskCount();
    final weeklyTasks = taskController.getWeeklyTaskCount();

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
                TodoLocalizations.of(context).name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TodoLocalizations.of(context).totalTasksCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$totalTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TodoLocalizations.of(context).weeklyTasksCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$weeklyTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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

  @override
  Future<void> uninstall() async {
    // 清理插件数据
    await storageManager.delete(storageDir);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 任务查询
      'getTasks': _jsGetTasks,
      'getTask': _jsGetTask,
      'getTodayTasks': _jsGetTodayTasks,
      'getOverdueTasks': _jsGetOverdueTasks,

      // 任务操作
      'createTask': _jsCreateTask,
      'updateTask': _jsUpdateTask,
      'deleteTask': _jsDeleteTask,
      'completeTask': _jsCompleteTask,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取任务列表
  /// 参数：status (可选), priority (可选)
  /// status: 'todo', 'inProgress', 'done'
  /// priority: 'low', 'medium', 'high'
  Future<String> _jsGetTasks([String? statusStr, String? priorityStr]) async {
    List<Task> tasks = taskController.tasks;

    // 状态过滤
    if (statusStr != null && statusStr.isNotEmpty) {
      TaskStatus? status;
      switch (statusStr.toLowerCase()) {
        case 'todo':
          status = TaskStatus.todo;
          break;
        case 'inprogress':
        case 'in_progress':
          status = TaskStatus.inProgress;
          break;
        case 'done':
          status = TaskStatus.done;
          break;
      }
      if (status != null) {
        tasks = tasks.where((t) => t.status == status).toList();
      }
    }

    // 优先级过滤
    if (priorityStr != null && priorityStr.isNotEmpty) {
      TaskPriority? priority;
      switch (priorityStr.toLowerCase()) {
        case 'low':
          priority = TaskPriority.low;
          break;
        case 'medium':
          priority = TaskPriority.medium;
          break;
        case 'high':
          priority = TaskPriority.high;
          break;
      }
      if (priority != null) {
        tasks = tasks.where((t) => t.priority == priority).toList();
      }
    }

    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }

  /// 获取任务详情
  /// 参数：taskId (必需)
  Future<String> _jsGetTask(String taskId) async {
    try {
      final task = taskController.tasks.firstWhere((t) => t.id == taskId);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '未找到任务: $taskId'});
    }
  }

  /// 获取今日任务（今天截止或今天开始的任务）
  Future<String> _jsGetTodayTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasks = taskController.tasks.where((task) {
      // 检查截止日期是否是今天
      if (task.dueDate != null) {
        final dueDay = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (dueDay == today) return true;
      }

      // 检查开始日期是否是今天
      if (task.startDate != null) {
        final startDay = DateTime(
          task.startDate!.year,
          task.startDate!.month,
          task.startDate!.day,
        );
        if (startDay == today) return true;
      }

      return false;
    }).toList();

    return jsonEncode(todayTasks.map((t) => t.toJson()).toList());
  }

  /// 获取过期任务（截止日期已过且未完成）
  Future<String> _jsGetOverdueTasks() async {
    final now = DateTime.now();

    final overdueTasks = taskController.tasks.where((task) {
      // 必须未完成
      if (task.status == TaskStatus.done) return false;

      // 必须有截止日期且已过期
      if (task.dueDate != null && task.dueDate!.isBefore(now)) {
        return true;
      }

      return false;
    }).toList();

    return jsonEncode(overdueTasks.map((t) => t.toJson()).toList());
  }

  /// 创建任务
  /// 参数：title (必需), description (可选), startDate (可选), dueDate (可选),
  ///       priority (可选), tags (可选, JSON 数组字符串)
  Future<String> _jsCreateTask(
    String title, [
    String? description,
    String? startDateStr,
    String? dueDateStr,
    String? priorityStr,
    String? tagsJsonStr,
  ]) async {
    try {
      // 解析优先级
      TaskPriority priority = TaskPriority.medium;
      if (priorityStr != null && priorityStr.isNotEmpty) {
        switch (priorityStr.toLowerCase()) {
          case 'low':
            priority = TaskPriority.low;
            break;
          case 'medium':
            priority = TaskPriority.medium;
            break;
          case 'high':
            priority = TaskPriority.high;
            break;
        }
      }

      // 解析日期
      DateTime? startDate;
      if (startDateStr != null && startDateStr.isNotEmpty) {
        startDate = DateTime.tryParse(startDateStr);
      }

      DateTime? dueDate;
      if (dueDateStr != null && dueDateStr.isNotEmpty) {
        dueDate = DateTime.tryParse(dueDateStr);
      }

      // 解析标签
      List<String> tags = [];
      if (tagsJsonStr != null && tagsJsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(tagsJsonStr);
          if (decoded is List) {
            tags = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // 如果解析失败，忽略标签
        }
      }

      // 创建任务
      final task = Task(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        startDate: startDate,
        dueDate: dueDate,
        priority: priority,
        tags: tags,
      );

      await taskController.addTask(task);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '创建任务失败: $e'});
    }
  }

  /// 更新任务
  /// 参数：taskId (必需), updateJson (必需, JSON 字符串)
  /// updateJson 格式: {"title": "新标题", "priority": "high", ...}
  Future<String> _jsUpdateTask(String taskId, String updateJsonStr) async {
    try {
      final task = taskController.tasks.firstWhere((t) => t.id == taskId);
      final updateData = jsonDecode(updateJsonStr) as Map<String, dynamic>;

      // 更新字段
      if (updateData.containsKey('title')) {
        task.title = updateData['title'] as String;
      }

      if (updateData.containsKey('description')) {
        task.description = updateData['description'] as String?;
      }

      if (updateData.containsKey('priority')) {
        final priorityStr = updateData['priority'] as String;
        switch (priorityStr.toLowerCase()) {
          case 'low':
            task.priority = TaskPriority.low;
            break;
          case 'medium':
            task.priority = TaskPriority.medium;
            break;
          case 'high':
            task.priority = TaskPriority.high;
            break;
        }
      }

      if (updateData.containsKey('status')) {
        final statusStr = updateData['status'] as String;
        switch (statusStr.toLowerCase()) {
          case 'todo':
            task.status = TaskStatus.todo;
            break;
          case 'inprogress':
          case 'in_progress':
            task.status = TaskStatus.inProgress;
            break;
          case 'done':
            task.status = TaskStatus.done;
            break;
        }
      }

      if (updateData.containsKey('startDate')) {
        task.startDate = DateTime.tryParse(updateData['startDate'] as String);
      }

      if (updateData.containsKey('dueDate')) {
        task.dueDate = DateTime.tryParse(updateData['dueDate'] as String);
      }

      if (updateData.containsKey('tags') && updateData['tags'] is List) {
        task.tags =
            (updateData['tags'] as List).map((e) => e.toString()).toList();
      }

      await taskController.updateTask(task);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '更新任务失败: $e'});
    }
  }

  /// 删除任务
  /// 参数：taskId (必需)
  Future<String> _jsDeleteTask(String taskId) async {
    try {
      await taskController.deleteTask(taskId);
      return jsonEncode({'success': true, 'taskId': taskId});
    } catch (e) {
      return jsonEncode({'error': '删除任务失败: $e'});
    }
  }

  /// 完成任务（标记为已完成）
  /// 参数：taskId (必需)
  Future<String> _jsCompleteTask(String taskId) async {
    try {
      await taskController.updateTaskStatus(taskId, TaskStatus.done);
      final task = taskController.tasks.firstWhere((t) => t.id == taskId);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '完成任务失败: $e'});
    }
  }
}
