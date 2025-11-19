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

class TodoPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  late TaskController taskController;
  late ReminderController reminderController;
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

      // 任务查找方法
      'findTaskBy': _jsFindTaskBy,
      'findTaskById': _jsFindTaskById,
      'findTaskByTitle': _jsFindTaskByTitle,
      'findTasksByTag': _jsFindTasksByTag,
      'findTasksByStatus': _jsFindTasksByStatus,
      'findTasksByPriority': _jsFindTasksByPriority,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取任务列表
  /// 参数对象: {
  ///   status: 'todo' | 'inProgress' | 'in_progress' | 'done' (可选),
  ///   priority: 'low' | 'medium' | 'high' (可选)
  /// }
  Future<String> _jsGetTasks(Map<String, dynamic> params) async {
    List<Task> tasks = taskController.tasks;

    final String? statusStr = params['status'];
    final String? priorityStr = params['priority'];

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
  /// 参数对象: { taskId: string (必需) }
  Future<String> _jsGetTask(Map<String, dynamic> params) async {
    final String? taskId = params['taskId'];

    if (taskId == null || taskId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: taskId'});
    }

    try {
      final task = taskController.tasks.firstWhere((t) => t.id == taskId);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '未找到任务: $taskId'});
    }
  }

  /// 获取今日任务（任务日期范围包含今天的任务）
  /// 参数对象: {} (无需参数,但保持接口一致性)
  Future<String> _jsGetTodayTasks(Map<String, dynamic> params) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasks = taskController.tasks.where((task) {
      // 如果任务既没有开始日期也没有截止日期,不算今日任务
      if (task.startDate == null && task.dueDate == null) {
        return false;
      }

      // 标准化日期(去掉时间部分)
      final startDay = task.startDate != null
          ? DateTime(
              task.startDate!.year,
              task.startDate!.month,
              task.startDate!.day,
            )
          : null;

      final dueDay = task.dueDate != null
          ? DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            )
          : null;

      // 检查任务的日期范围是否包含今天
      // 条件:startDate <= today 且 dueDate >= today
      if (startDay != null && dueDay != null) {
        // 两个日期都存在:检查今天是否在范围内
        return !startDay.isAfter(today) && !dueDay.isBefore(today);
      } else if (startDay != null) {
        // 只有开始日期:检查是否已开始(开始日期 <= 今天)
        return !startDay.isAfter(today);
      } else if (dueDay != null) {
        // 只有截止日期:检查是否未过期(截止日期 >= 今天)
        return !dueDay.isBefore(today);
      }

      return false;
    }).toList();

    return jsonEncode(todayTasks.map((t) => t.toJson()).toList());
  }

  /// 获取过期任务（截止日期已过且未完成）
  /// 参数对象: {} (无需参数,但保持接口一致性)
  Future<String> _jsGetOverdueTasks(Map<String, dynamic> params) async {
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
  /// 参数对象: {
  ///   title: string (必需),
  ///   id: string (可选, 自定义ID),
  ///   description: string (可选),
  ///   startDate: string (可选, ISO 8601 格式),
  ///   dueDate: string (可选, ISO 8601 格式),
  ///   priority: 'low' | 'medium' | 'high' (可选, 默认 'medium'),
  ///   tags: string (可选, JSON 数组字符串, 如 '["工作","紧急"]')
  /// }
  Future<String> _jsCreateTask(Map<String, dynamic> params) async {
    try {
      final String? title = params['title'];

      // 验证必需参数
      if (title == null || title.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: title'});
      }

      final String? id = params['id'];
      final String? description = params['description'];
      final String? startDateStr = params['startDate'];
      final String? dueDateStr = params['dueDate'];
      final String priorityStr = params['priority'] ?? 'medium';
      final String? tagsJsonStr = params['tags'];

      // 检查自定义ID是否已存在
      if (id != null && id.isNotEmpty) {
        final existingTask = taskController.tasks.where((t) => t.id == id).firstOrNull;
        if (existingTask != null) {
          return jsonEncode({'error': '任务ID已存在: $id'});
        }
      }

      // 解析优先级
      TaskPriority priority = TaskPriority.medium;
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
        id: (id != null && id.isNotEmpty) ? id : const Uuid().v4(),
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
  /// 参数对象: {
  ///   taskId: string (必需),
  ///   updates: {
  ///     title: string (可选),
  ///     description: string (可选),
  ///     priority: 'low' | 'medium' | 'high' (可选),
  ///     status: 'todo' | 'inProgress' | 'in_progress' | 'done' (可选),
  ///     startDate: string (可选, ISO 8601 格式),
  ///     dueDate: string (可选, ISO 8601 格式),
  ///     tags: array (可选, 标签数组)
  ///   } (必需)
  /// }
  Future<String> _jsUpdateTask(Map<String, dynamic> params) async {
    try {
      final String? taskId = params['taskId'];
      final dynamic updatesData = params['updates'];

      // 验证必需参数
      if (taskId == null || taskId.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: taskId'});
      }

      if (updatesData == null) {
        return jsonEncode({'error': '缺少必需参数: updates'});
      }

      // 解析 updates 参数
      Map<String, dynamic> updateData;
      if (updatesData is String) {
        updateData = jsonDecode(updatesData) as Map<String, dynamic>;
      } else if (updatesData is Map) {
        updateData = Map<String, dynamic>.from(updatesData);
      } else {
        return jsonEncode({'error': 'updates 参数格式错误,必须是对象或 JSON 字符串'});
      }

      final task = taskController.tasks.firstWhere((t) => t.id == taskId);

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
  /// 参数对象: { taskId: string (必需) }
  Future<String> _jsDeleteTask(Map<String, dynamic> params) async {
    try {
      final String? taskId = params['taskId'];

      // 验证必需参数
      if (taskId == null || taskId.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: taskId'});
      }

      await taskController.deleteTask(taskId);
      return jsonEncode({'success': true, 'taskId': taskId});
    } catch (e) {
      return jsonEncode({'error': '删除任务失败: $e'});
    }
  }

  /// 完成任务（标记为已完成）
  /// 参数对象: { taskId: string (必需) }
  Future<String> _jsCompleteTask(Map<String, dynamic> params) async {
    try {
      final String? taskId = params['taskId'];

      // 验证必需参数
      if (taskId == null || taskId.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: taskId'});
      }

      await taskController.updateTaskStatus(taskId, TaskStatus.done);
      final task = taskController.tasks.firstWhere((t) => t.id == taskId);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode({'error': '完成任务失败: $e'});
    }
  }

  // ==================== 任务查找方法 ====================

  /// 通用任务查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindTaskBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    final tasks = taskController.tasks;
    final List<Task> matchedTasks = [];

    for (final task in tasks) {
      final taskJson = task.toJson();

      // 检查字段是否匹配
      if (taskJson.containsKey(field) && taskJson[field] == value) {
        matchedTasks.add(task);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      return jsonEncode(matchedTasks.map((t) => t.toJson()).toList());
    } else {
      if (matchedTasks.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedTasks.first.toJson());
    }
  }

  /// 根据ID查找任务
  /// @param params.id 任务ID (必需)
  Future<String> _jsFindTaskById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final task = taskController.tasks.firstWhere((t) => t.id == id);
      return jsonEncode(task.toJson());
    } catch (e) {
      return jsonEncode(null);
    }
  }

  /// 根据标题查找任务
  /// @param params.title 任务标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindTaskByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    final tasks = taskController.tasks;
    final List<Task> matchedTasks = [];

    for (final task in tasks) {
      bool matches = false;
      if (fuzzy) {
        matches = task.title.contains(title);
      } else {
        matches = task.title == title;
      }

      if (matches) {
        matchedTasks.add(task);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedTasks.map((t) => t.toJson()).toList());
    } else {
      if (matchedTasks.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedTasks.first.toJson());
    }
  }

  /// 根据标签查找任务
  /// @param params.tag 标签名称 (必需)
  /// @param params.status 可选的状态过滤
  /// @param params.priority 可选的优先级过滤
  Future<String> _jsFindTasksByTag(Map<String, dynamic> params) async {
    final String? tag = params['tag'];
    if (tag == null || tag.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: tag'});
    }

    final String? statusStr = params['status'];
    final String? priorityStr = params['priority'];

    List<Task> tasks = taskController.tasks.where((t) => t.tags.contains(tag)).toList();

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

  /// 根据状态查找任务
  /// @param params.status 任务状态 (必需)
  /// @param params.startDate 开始日期过滤 (可选)
  /// @param params.endDate 结束日期过滤 (可选)
  Future<String> _jsFindTasksByStatus(Map<String, dynamic> params) async {
    final String? statusStr = params['status'];
    if (statusStr == null || statusStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: status'});
    }

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

    if (status == null) {
      return jsonEncode({'error': '无效的状态值: $statusStr'});
    }

    List<Task> tasks = taskController.tasks.where((t) => t.status == status).toList();

    // 日期过滤
    final String? startDateStr = params['startDate'];
    final String? endDateStr = params['endDate'];

    if (startDateStr != null || endDateStr != null) {
      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null && startDateStr.isNotEmpty) {
        startDate = DateTime.tryParse(startDateStr);
      }
      if (endDateStr != null && endDateStr.isNotEmpty) {
        endDate = DateTime.tryParse(endDateStr);
      }

      tasks = tasks.where((task) {
        final taskDate = task.completedDate ?? task.dueDate;
        if (taskDate == null) return false;

        if (startDate != null && taskDate.isBefore(startDate)) return false;
        if (endDate != null && taskDate.isAfter(endDate)) return false;

        return true;
      }).toList();
    }

    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }

  /// 根据优先级查找任务
  /// @param params.priority 优先级 (必需)
  /// @param params.status 可选的状态过滤
  Future<String> _jsFindTasksByPriority(Map<String, dynamic> params) async {
    final String? priorityStr = params['priority'];
    if (priorityStr == null || priorityStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: priority'});
    }

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

    if (priority == null) {
      return jsonEncode({'error': '无效的优先级值: $priorityStr'});
    }

    List<Task> tasks = taskController.tasks.where((t) => t.priority == priority).toList();

    // 可选的状态过滤
    final String? statusStr = params['status'];
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

    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }
}
