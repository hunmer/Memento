import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../core/event/event_manager.dart';
import '../../../core/event/item_event_args.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';

// 排序方式枚举，移到类外部
enum SortBy { dueDate, priority, custom }

class TaskController extends ChangeNotifier {
  final StorageManager _storage;
  final String _storageDir;
  List<Task> _tasks = [];

  // 发送事件通知
  void _notifyEvent(String action, Task task) {
    final eventArgs = ItemEventArgs(
      eventName: 'task_$action',
      itemId: task.id,
      title: task.title,
      action: action,
    );
    EventManager.instance.broadcast('task_$action', eventArgs);
  }

  // 视图模式
  bool _isGridView = false;

  // 排序方式
  SortBy _sortBy = SortBy.dueDate;

  TaskController(this._storage, this._storageDir) {
    _loadTasks();
  }

  // 过滤状态
  List<Task> _filteredTasks = [];
  Map<String, dynamic>? _currentFilter;

  // Getters
  List<Task> get tasks => _currentFilter != null ? _filteredTasks : _tasks;
  bool get isGridView => _isGridView;
  SortBy get sortBy => _sortBy;

  // 切换视图模式
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // 设置排序方式
  void setSortBy(SortBy sortBy) {
    _sortBy = sortBy;
    _sortTasks();
    if (_currentFilter != null) {
      _applyFilter(_currentFilter!);
    }
    notifyListeners();
  }

  // 应用过滤
  void applyFilter(Map<String, dynamic> filter) {
    _currentFilter = filter;
    _applyFilter(filter);

    // 确保在UI线程安全地通知监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 清除过滤
  void clearFilter() {
    _currentFilter = null;
    notifyListeners();
  }

  // 实际执行过滤逻辑
  void _applyFilter(Map<String, dynamic> filter) {
    _filteredTasks =
        _tasks.where((task) {
          // 关键词过滤
          final keyword = filter['keyword'] as String?;
          if (keyword != null && keyword.isNotEmpty) {
            final keywordMatch =
                task.title.toLowerCase().contains(keyword.toLowerCase()) ||
                (task.description != null &&
                    task.description!.toLowerCase().contains(
                      keyword.toLowerCase(),
                    ));
            if (!keywordMatch) return false;
          }

          // 优先级过滤
          final priority = filter['priority'] as TaskPriority?;
          if (priority != null && task.priority != priority) {
            return false;
          }

          // 标签过滤
          final tags = filter['tags'] as List<String>?;
          if (tags != null && tags.isNotEmpty) {
            final hasAllTags = tags.every((tag) => task.tags.contains(tag));
            if (!hasAllTags) return false;
          }

          // 日期范围过滤
          final filterStartDate = filter['startDate'] as DateTime?;
          final filterEndDate = filter['endDate'] as DateTime?;
          if (filterStartDate != null || filterEndDate != null) {
            // 如果任务没有开始日期和截止日期，则不符合过滤条件
            if (task.startDate == null && task.dueDate == null) return false;

            // 检查任务的日期范围是否与过滤条件有交集
            if (filterStartDate != null) {
              // 如果任务有截止日期，且截止日期早于过滤的开始日期，则不符合条件
              if (task.dueDate != null &&
                  task.dueDate!.isBefore(filterStartDate)) {
                return false;
              }
              // 如果任务只有开始日期，没有截止日期，且开始日期早于过滤的开始日期，则不符合条件
              if (task.dueDate == null &&
                  task.startDate != null &&
                  task.startDate!.isBefore(filterStartDate)) {
                return false;
              }
            }

            if (filterEndDate != null) {
              // 如果任务有开始日期，且开始日期晚于过滤的截止日期，则不符合条件
              if (task.startDate != null &&
                  task.startDate!.isAfter(filterEndDate)) {
                return false;
              }
              // 如果任务只有截止日期，没有开始日期，且截止日期晚于过滤的截止日期，则不符合条件
              if (task.startDate == null &&
                  task.dueDate != null &&
                  task.dueDate!.isAfter(filterEndDate)) {
                return false;
              }
            }
          }

          // 完成状态过滤
          final showCompleted = filter['showCompleted'] as bool? ?? true;
          final showIncomplete = filter['showIncomplete'] as bool? ?? true;
          if (!showCompleted && task.status == TaskStatus.done) {
            return false;
          }
          if (!showIncomplete && task.status != TaskStatus.done) {
            return false;
          }

          return true;
        }).toList();
    _sortTasks();
  }

  // 根据当前排序方式对任务进行排序
  void _sortTasks() {
    switch (_sortBy) {
      case SortBy.dueDate:
        _tasks.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case SortBy.priority:
        _tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case SortBy.custom:
        // 自定义排序逻辑，这里可以根据需要实现
        break;
    }
  }

  // 加载任务
  Future<void> _loadTasks() async {
    final data = await _storage.read('$_storageDir/tasks.json');
    if (data.isNotEmpty) {
      final List<dynamic> taskList = data['tasks'] as List<dynamic>;
      _tasks = taskList.map((item) => Task.fromJson(item)).toList();

      // 加载已完成任务历史
      if (data['completedTasks'] != null) {
        final List<dynamic> completedTaskList =
            data['completedTasks'] as List<dynamic>;
        _completedTasks =
            completedTaskList.map((item) => Task.fromJson(item)).toList();
      }

      _sortTasks();
      notifyListeners();
    } else {
      // 首次初始化，创建默认任务
      await _createDefaultTasks();
    }
  }

  // 创建默认任务
  Future<void> _createDefaultTasks() async {
    final now = DateTime.now();

    // 任务1：欢迎任务
    final welcomeTask = Task(
      id: const Uuid().v4(),
      title: '欢迎使用待办事项',
      description: '这是你的第一个任务！点击任务可以查看详情、编辑或标记完成。',
      createdAt: now,
      dueDate: now.add(const Duration(days: 1)),
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      tags: ['入门'],
    );

    // 任务2：带子任务的示例
    final projectTask = Task(
      id: const Uuid().v4(),
      title: '完成项目计划',
      description: '制定本周的工作计划，包含多个子任务',
      createdAt: now,
      startDate: now,
      dueDate: now.add(const Duration(days: 3)),
      priority: TaskPriority.medium,
      status: TaskStatus.todo,
      tags: ['工作', '计划'],
      subtasks: [
        Subtask(
          id: const Uuid().v4(),
          title: '收集需求',
          isCompleted: false,
        ),
        Subtask(
          id: const Uuid().v4(),
          title: '设计方案',
          isCompleted: false,
        ),
        Subtask(
          id: const Uuid().v4(),
          title: '评审确认',
          isCompleted: false,
        ),
      ],
    );

    // 任务3：日常任务
    final dailyTask = Task(
      id: const Uuid().v4(),
      title: '每日锻炼30分钟',
      description: '保持健康的生活习惯',
      createdAt: now,
      dueDate: now,
      priority: TaskPriority.medium,
      status: TaskStatus.todo,
      tags: ['健康', '日常'],
    );

    // 任务4：低优先级任务
    final readingTask = Task(
      id: const Uuid().v4(),
      title: '阅读《Flutter实战》',
      description: '学习Flutter高级特性',
      createdAt: now,
      startDate: now,
      dueDate: now.add(const Duration(days: 7)),
      priority: TaskPriority.low,
      status: TaskStatus.todo,
      tags: ['学习', '阅读'],
    );

    // 添加所有默认任务
    _tasks.addAll([welcomeTask, projectTask, dailyTask, readingTask]);

    // 排序并保存
    _sortTasks();
    await _saveTasks();
    notifyListeners();
  }

  // 保存任务
  Future<void> _saveTasks() async {
    final data = {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'completedTasks': _completedTasks.map((task) => task.toJson()).toList(),
    };
    await _storage.write('$_storageDir/tasks.json', data);
  }

  // 添加任务
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    // 发送添加事件
    _notifyEvent('added', task);
    _sortTasks();
    notifyListeners();
    await _saveTasks();
    await _syncWidget();
  }

  // 创建新任务
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String>? tags,
    List<Subtask>? subtasks,
    List<DateTime>? reminders,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      startDate: startDate,
      dueDate: dueDate,
      priority: priority,
      status: TaskStatus.todo,
      tags: tags,
      subtasks: subtasks,
      reminders: reminders,
    );

    await addTask(task);
    return task;
  }

  // 更新任务
  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _sortTasks();
      notifyListeners();
      await _saveTasks();
      await _syncWidget();
    }
  }

  // 已完成任务历史
  List<Task> _completedTasks = [];

  List<Task> get completedTasks => _completedTasks;

  // 删除任务
  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (task.status == TaskStatus.done) {
      // 如果是已完成任务，添加到历史记录
      _completedTasks.add(task.copyWith(completedDate: DateTime.now()));
      _notifyEvent('completed', task);
    }
    _tasks.removeWhere((task) => task.id == taskId);
    // 发送删除事件
    _notifyEvent('deleted', task);
    notifyListeners();
    await _saveTasks();
    await _syncWidget();
  }

  // 从历史记录中删除任务
  Future<void> removeFromHistory(String taskId) async {
    _completedTasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
    await _saveTasks();
    await _syncWidget();
  }

  // 更新任务状态
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final oldStatus = task.status;

      // 如果任务正在进行中，先停止计时
      if (oldStatus == TaskStatus.inProgress) {
        task.stopTimer();
      }

      task.status = status;

      // 如果新状态是进行中，开始计时
      if (status == TaskStatus.inProgress) {
        task.startTimer();
      }

      // 如果任务标记为完成，停止计时并自动标记所有子任务为完成
      if (status == TaskStatus.done) {
        task.completeTask();
        for (var subtask in task.subtasks) {
          subtask.isCompleted = true;
        }
      }

      notifyListeners();
      await _saveTasks();
      await _syncWidget();
    }
  }

  // 添加子任务
  Future<void> addSubtask(String taskId, String title) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].subtasks.add(Subtask(id: const Uuid().v4(), title: title));
      notifyListeners();
      await _saveTasks();
      await _syncWidget();
    }
  }

  // 更新子任务状态
  Future<void> updateSubtaskStatus(
    String taskId,
    String subtaskId,
    bool isCompleted,
  ) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final subtaskIndex = _tasks[taskIndex].subtasks.indexWhere(
        (s) => s.id == subtaskId,
      );
      if (subtaskIndex != -1) {
        _tasks[taskIndex].subtasks[subtaskIndex].isCompleted = isCompleted;

        // 检查所有子任务是否都已完成，如果是，则将任务标记为完成
        final allCompleted = _tasks[taskIndex].subtasks.every(
          (s) => s.isCompleted,
        );
        if (allCompleted && _tasks[taskIndex].subtasks.isNotEmpty) {
          _tasks[taskIndex].status = TaskStatus.done;
        } else if (_tasks[taskIndex].status == TaskStatus.done) {
          _tasks[taskIndex].status = TaskStatus.inProgress;
        }

        notifyListeners();
        await _saveTasks();
        await _syncWidget();
      }
    }
  }

  // 按标签获取任务
  List<Task> getTasksByTag(String tag) {
    return _tasks.where((task) => task.tags.contains(tag)).toList();
  }

  // 获取所有标签
  List<String> getAllTags() {
    final Set<String> tagSet = {};
    for (var task in _tasks) {
      tagSet.addAll(task.tags);
    }
    return tagSet.toList();
  }

  // 添加标签到任务
  Future<void> addTagToTask(String taskId, String tag) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1 && !_tasks[index].tags.contains(tag)) {
      _tasks[index].tags.add(tag);
      notifyListeners();
      await _saveTasks();
    }
  }

  // 从任务中移除标签
  Future<void> removeTagFromTask(String taskId, String tag) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].tags.remove(tag);
      notifyListeners();
      await _saveTasks();
    }
  }

  // 获取指定状态的任务数量
  int getTaskCountByStatus(TaskStatus status, {String? tag}) {
    if (tag != null) {
      return _tasks
          .where((task) => task.status == status && task.tags.contains(tag))
          .length;
    }
    return _tasks.where((task) => task.status == status).length;
  }

  // 获取未完成任务数量
  int getIncompleteTaskCount({String? tag}) {
    return getTaskCountByStatus(TaskStatus.todo, tag: tag) +
        getTaskCountByStatus(TaskStatus.inProgress, tag: tag);
  }

  // 获取总任务数量
  int getTotalTaskCount() {
    return _tasks.length;
  }

  // 获取最近7天的任务数量
  int getWeeklyTaskCount() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _tasks.where((task) {
      return (task.createdAt.isAfter(sevenDaysAgo) ||
          (task.dueDate != null && task.dueDate!.isAfter(sevenDaysAgo)));
    }).length;
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    // 同步标准待办小组件 (1x1/2x2)
    await PluginWidgetSyncHelper.instance.syncTodo();
    // 同步待办列表自定义小组件（可滚动列表）
    await PluginWidgetSyncHelper.instance.syncTodoListWidget();
  }
}
