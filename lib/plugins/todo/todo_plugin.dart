import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'controllers/controllers.dart';
import 'models/models.dart';
import 'views/todo_bottombar_view.dart';

// 导入 UseCase 相关
import 'package:shared_models/shared_models.dart';
import 'repositories/client_todo_repository.dart';

class TodoPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  late TaskController taskController;
  late ReminderController reminderController;

  // UseCase 相关
  late ClientTodoRepository _repository;
  late TodoUseCase _todoUseCase;

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
    return 'todo_name'.tr;
  }

  @override
  Future<void> initialize() async {
    taskController = TaskController(storageManager, storageDir);
    reminderController = ReminderController();

    // 初始化提醒控制器（使用系统日历）
    await reminderController.initialize();

    // 创建 Repository 和 UseCase 实例
    _repository = ClientTodoRepository(taskController);
    _todoUseCase = TodoUseCase(_repository);

    // 加载默认设置
    await loadSettings({
      'defaultView': 'list', // 'list' or 'grid'
      'defaultSortBy': 'dueDate', // 'dueDate', 'priority', or 'custom'
      'reminderAdvanceTime': 60, // minutes
    });

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件相关服务
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const TodoBottomBarView();
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
                'todo_name'.tr,
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
                    'todo_totalTasksCount'.tr,
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
                    'todo_weeklyTasksCount'.tr,
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

  // ==================== 状态标准化 ====================

  /// 将各种状态字符串标准化为 TaskStatus
  /// 支持的输入格式:
  /// - 标准: 'todo', 'inProgress', 'in_progress', 'done'
  /// - 别名: 'completed', 'complete', 'finished' → done
  /// - 别名: 'waiting', 'pending', 'open' → todo
  /// - 别名: 'working', 'active', 'started' → inProgress
  /// - 数字: '0' → todo, '1' → inProgress, '2' → done
  TaskStatus? _normalizeStatus(String? statusStr) {
    if (statusStr == null || statusStr.isEmpty) {
      return null;
    }

    final normalized = statusStr.toLowerCase().trim();

    // 标准值
    switch (normalized) {
      case 'todo':
      case 'waiting':
      case 'pending':
      case 'open':
      case '0':
        return TaskStatus.todo;

      case 'inprogress':
      case 'in_progress':
      case 'working':
      case 'active':
      case 'started':
      case '1':
        return TaskStatus.inProgress;

      case 'done':
      case 'completed':
      case 'complete':
      case 'finished':
      case '2':
        return TaskStatus.done;

      default:
        return null;
    }
  }

  // ==================== JS API 实现 ====================

  /// 获取任务列表
  /// 参数对象: {
  ///   status: 'todo' | 'inProgress' | 'in_progress' | 'done' (可选),
  ///   priority: 'low' | 'medium' | 'high' (可选),
  ///   offset: number (可选, 分页起始位置),
  ///   count: number (可选, 返回数量)
  /// }
  Future<String> _jsGetTasks(Map<String, dynamic> params) async {
    // 转换参数格式
    final useCaseParams = <String, dynamic>{};

    // 状态过滤
    if (params.containsKey('status')) {
      final statusStr = params['status'] as String;
      useCaseParams['completed'] = statusStr == 'done';
    }

    // 优先级过滤
    if (params.containsKey('priority')) {
      final priorityStr = params['priority'] as String;
      switch (priorityStr.toLowerCase()) {
        case 'low':
          useCaseParams['priority'] = 0;
          break;
        case 'medium':
          useCaseParams['priority'] = 1;
          break;
        case 'high':
          useCaseParams['priority'] = 2;
          break;
      }
    }

    // 分页参数
    if (params.containsKey('offset')) {
      useCaseParams['offset'] = params['offset'] as int;
    }
    if (params.containsKey('count')) {
      useCaseParams['count'] = params['count'] as int;
    }

    // 调用 UseCase
    final result = await _todoUseCase.getTasks(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull!.message});
    }
  }

  /// 获取任务详情
  /// 参数对象: { taskId: string (必需) }
  Future<String> _jsGetTask(Map<String, dynamic> params) async {
    final String? taskId = params['taskId'];

    if (taskId == null || taskId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: taskId'});
    }

    // 调用 UseCase
    final result = await _todoUseCase.getTaskById({'id': taskId});

    if (result.isSuccess) {
      final taskData = result.dataOrNull;
      if (taskData == null) {
        return jsonEncode({'error': '未找到任务: $taskId'});
      }
      return jsonEncode(taskData);
    } else {
      return jsonEncode({'error': result.errorOrNull!.message});
    }
  }

  /// 获取今日任务（任务日期范围包含今天的任务）
  /// 参数对象: { offset: number (可选), count: number (可选) }
  Future<String> _jsGetTodayTasks(Map<String, dynamic> params) async {
    // 转换分页参数
    final useCaseParams = <String, dynamic>{};
    if (params.containsKey('offset')) {
      useCaseParams['offset'] = params['offset'] as int;
    }
    if (params.containsKey('count')) {
      useCaseParams['count'] = params['count'] as int;
    }

    // 调用 UseCase
    final result = await _todoUseCase.getTodayTasks(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull!.message});
    }
  }

  /// 获取过期任务（截止日期已过且未完成）
  /// 参数对象: { offset: number (可选), count: number (可选) }
  Future<String> _jsGetOverdueTasks(Map<String, dynamic> params) async {
    // 转换分页参数
    final useCaseParams = <String, dynamic>{};
    if (params.containsKey('offset')) {
      useCaseParams['offset'] = params['offset'] as int;
    }
    if (params.containsKey('count')) {
      useCaseParams['count'] = params['count'] as int;
    }

    // 调用 UseCase
    final result = await _todoUseCase.getOverdueTasks(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull!.message});
    }
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
      // 转换参数格式
      final useCaseParams = <String, dynamic>{};

      // 必需参数
      if (params.containsKey('title')) {
        useCaseParams['title'] = params['title'];
      }

      // 可选参数
      if (params.containsKey('id')) {
        useCaseParams['id'] = params['id'];
      }
      if (params.containsKey('description')) {
        useCaseParams['description'] = params['description'];
      }
      if (params.containsKey('startDate')) {
        useCaseParams['startDate'] = params['startDate'];
      }
      if (params.containsKey('dueDate')) {
        useCaseParams['dueDate'] = params['dueDate'];
      }

      // 优先级转换
      if (params.containsKey('priority')) {
        final priorityStr = params['priority'] as String;
        int priority = 1; // 默认 medium
        switch (priorityStr.toLowerCase()) {
          case 'low':
            priority = 0;
            break;
          case 'high':
            priority = 2;
            break;
        }
        useCaseParams['priority'] = priority;
      }

      // 标签解析
      if (params.containsKey('tags')) {
        final tagsJsonStr = params['tags'] as String;
        if (tagsJsonStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(tagsJsonStr);
            if (decoded is List) {
              useCaseParams['tags'] = decoded;
            }
          } catch (e) {
            // 如果解析失败，忽略标签
          }
        }
      }

      // 调用 UseCase
      final result = await _todoUseCase.createTask(useCaseParams);

      if (result.isSuccess) {
        return jsonEncode(result.dataOrNull);
      } else {
        return jsonEncode({'error': result.errorOrNull!.message});
      }
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

      // 转换参数格式
      final useCaseParams = <String, dynamic>{};
      useCaseParams['id'] = taskId;

      // 转换更新字段
      if (updateData.containsKey('title')) {
        useCaseParams['title'] = updateData['title'];
      }
      if (updateData.containsKey('description')) {
        useCaseParams['description'] = updateData['description'];
      }
      if (updateData.containsKey('startDate')) {
        useCaseParams['startDate'] = updateData['startDate'];
      }
      if (updateData.containsKey('dueDate')) {
        useCaseParams['dueDate'] = updateData['dueDate'];
      }
      if (updateData.containsKey('tags') && updateData['tags'] is List) {
        useCaseParams['tags'] = updateData['tags'];
      }

      // 优先级转换
      if (updateData.containsKey('priority')) {
        final priorityStr = updateData['priority'] as String;
        int priority = 1; // 默认 medium
        switch (priorityStr.toLowerCase()) {
          case 'low':
            priority = 0;
            break;
          case 'high':
            priority = 2;
            break;
        }
        useCaseParams['priority'] = priority;
      }

      // 状态转换
      if (updateData.containsKey('status')) {
        final statusStr = updateData['status'] as String;
        useCaseParams['completed'] = statusStr == 'done';
      }

      // 调用 UseCase
      final result = await _todoUseCase.updateTask(useCaseParams);

      if (result.isSuccess) {
        return jsonEncode(result.dataOrNull);
      } else {
        return jsonEncode({'error': result.errorOrNull!.message});
      }
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

      // 调用 UseCase
      final result = await _todoUseCase.deleteTask({'id': taskId});

      if (result.isSuccess) {
        return jsonEncode({'success': true, 'taskId': taskId});
      } else {
        return jsonEncode({'error': result.errorOrNull!.message});
      }
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

      // 调用 UseCase
      final result = await _todoUseCase.completeTask({'id': taskId});

      if (result.isSuccess) {
        return jsonEncode(result.dataOrNull);
      } else {
        return jsonEncode({'error': result.errorOrNull!.message});
      }
    } catch (e) {
      return jsonEncode({'error': '完成任务失败: $e'});
    }
  }

  // ==================== 任务查找方法 ====================

  /// 通用任务查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置（仅 findAll=true 时有效）
  /// @param params.count 返回数量（仅 findAll=true 时有效）
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
    final int? offset = params['offset'];
    final int? count = params['count'];

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
      final tasksJson = matchedTasks.map((t) => t.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          tasksJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(tasksJson);
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
  /// @param params.offset 分页起始位置（仅 findAll=true 时有效）
  /// @param params.count 返回数量（仅 findAll=true 时有效）
  Future<String> _jsFindTaskByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

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
      final tasksJson = matchedTasks.map((t) => t.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          tasksJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(tasksJson);
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
  /// @param params.offset 分页起始位置
  /// @param params.count 返回数量
  Future<String> _jsFindTasksByTag(Map<String, dynamic> params) async {
    final String? tag = params['tag'];
    if (tag == null || tag.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: tag'});
    }

    final String? statusStr = params['status'];
    final String? priorityStr = params['priority'];

    List<Task> tasks = taskController.tasks.where((t) => t.tags.contains(tag)).toList();

    // 状态过滤
    final status = _normalizeStatus(statusStr);
    if (status != null) {
      tasks = tasks.where((t) => t.status == status).toList();
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

    final tasksJson = tasks.map((t) => t.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        tasksJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(tasksJson);
  }

  /// 根据状态查找任务
  /// @param params.status 任务状态 (必需)
  /// @param params.startDate 开始日期过滤 (可选)
  /// @param params.endDate 结束日期过滤 (可选)
  /// @param params.offset 分页起始位置
  /// @param params.count 返回数量
  Future<String> _jsFindTasksByStatus(Map<String, dynamic> params) async {
    final String? statusStr = params['status'];
    if (statusStr == null || statusStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: status'});
    }

    final status = _normalizeStatus(statusStr);
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

    final tasksJson = tasks.map((t) => t.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        tasksJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(tasksJson);
  }

  /// 根据优先级查找任务
  /// @param params.priority 优先级 (必需)
  /// @param params.status 可选的状态过滤
  /// @param params.offset 分页起始位置
  /// @param params.count 返回数量
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
    final status = _normalizeStatus(statusStr);
    if (status != null) {
      tasks = tasks.where((t) => t.status == status).toList();
    }

    final tasksJson = tasks.map((t) => t.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        tasksJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(tasksJson);
  }

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'todo.task',
      pluginId: id,
      name: '选择任务',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'task',
          title: '选择任务',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return taskController.tasks.map((task) {
              // 构建副标题：状态 + 优先级 + 日期
              final statusText = task.status == TaskStatus.todo
                  ? '待办'
                  : task.status == TaskStatus.inProgress
                      ? '进行中'
                      : '已完成';
              final priorityText = task.priority == TaskPriority.low
                  ? '低优先级'
                  : task.priority == TaskPriority.medium
                      ? '中优先级'
                      : '高优先级';
              final dueDateText = task.dueDate != null
                  ? ' | ${task.dueDate!.month}/${task.dueDate!.day}'
                  : '';

              return SelectableItem(
                id: task.id,
                title: task.title,
                subtitle: '$statusText | $priorityText$dueDateText',
                icon: task.statusIcon,
                rawData: task,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final titleMatch = item.title.toLowerCase().contains(lowerQuery);
              final task = item.rawData as Task;
              final descriptionMatch = task.description?.toLowerCase().contains(lowerQuery) ?? false;
              final tagsMatch = task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
              return titleMatch || descriptionMatch || tagsMatch;
            }).toList();
          },
        ),
      ],
    ));
  }
}
