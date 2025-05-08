import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../../core/storage/storage_manager.dart';
import 'package:uuid/uuid.dart';

// 排序方式枚举，移到类外部
enum SortBy { dueDate, priority, custom }

class TaskController extends ChangeNotifier {
  final StorageManager _storage;
  final String _storageDir;
  List<Task> _tasks = [];
  
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
    print('Applying filter: $filter');
    _currentFilter = filter;
    _applyFilter(filter);
    print('Filtered tasks count: ${_filteredTasks.length}');
    
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
    print('Original tasks count: ${_tasks.length}');
    _filteredTasks = _tasks.where((task) {
      print('Checking task: ${task.title}');
      // 关键词过滤
      final keyword = filter['keyword'] as String?;
      if (keyword != null && keyword.isNotEmpty) {
        final keywordMatch = task.title.toLowerCase().contains(keyword.toLowerCase()) ||
            (task.description != null && 
             task.description!.toLowerCase().contains(keyword.toLowerCase()));
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
      final startDate = filter['startDate'] as DateTime?;
      final endDate = filter['endDate'] as DateTime?;
      if (startDate != null || endDate != null) {
        if (task.dueDate == null) return false;
        if (startDate != null && task.dueDate!.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && task.dueDate!.isAfter(endDate)) {
          return false;
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
    try {
      final data = await _storage.read('$_storageDir/tasks.json');
      if (data.isNotEmpty) {
        final List<dynamic> taskList = data['tasks'] as List<dynamic>;
        _tasks = taskList.map((item) => Task.fromJson(item)).toList();
        _sortTasks();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  // 保存任务
  Future<void> _saveTasks() async {
    try {
      final data = {
        'tasks': _tasks.map((task) => task.toJson()).toList()
      };
      await _storage.write('$_storageDir/tasks.json', data);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  // 添加任务
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    _sortTasks();
    notifyListeners();
    await _saveTasks();
  }

  // 创建新任务
  Future<Task> createTask({
    required String title,
    String? description,
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
    }
  }

  // 删除任务
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
    await _saveTasks();
  }

  // 更新任务状态
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].status = status;
      
      // 如果任务标记为完成，自动标记所有子任务为完成
      if (status == TaskStatus.done) {
        for (var subtask in _tasks[index].subtasks) {
          subtask.isCompleted = true;
        }
      }
      
      notifyListeners();
      await _saveTasks();
    }
  }

  // 添加子任务
  Future<void> addSubtask(String taskId, String title) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].subtasks.add(
        Subtask(
          id: const Uuid().v4(),
          title: title,
        ),
      );
      notifyListeners();
      await _saveTasks();
    }
  }

  // 更新子任务状态
  Future<void> updateSubtaskStatus(String taskId, String subtaskId, bool isCompleted) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final subtaskIndex = _tasks[taskIndex].subtasks.indexWhere((s) => s.id == subtaskId);
      if (subtaskIndex != -1) {
        _tasks[taskIndex].subtasks[subtaskIndex].isCompleted = isCompleted;
        
        // 检查所有子任务是否都已完成，如果是，则将任务标记为完成
        final allCompleted = _tasks[taskIndex].subtasks.every((s) => s.isCompleted);
        if (allCompleted && _tasks[taskIndex].subtasks.isNotEmpty) {
          _tasks[taskIndex].status = TaskStatus.done;
        } else if (_tasks[taskIndex].status == TaskStatus.done) {
          _tasks[taskIndex].status = TaskStatus.inProgress;
        }
        
        notifyListeners();
        await _saveTasks();
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
      return _tasks.where((task) => 
        task.status == status && task.tags.contains(tag)
      ).length;
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
}