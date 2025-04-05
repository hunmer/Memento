import 'dart:math';
import '../models/task_item.dart';

class TodoService {
  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  TodoService._internal();

  final List<TaskItem> _tasks = [];
  final List<String> _groups = ['个人', '工作', '学习', '家庭'];
  final List<String> _tags = ['重要', '紧急', '会议', '项目', '阅读'];

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<String> get groups => List.unmodifiable(_groups);
  List<String> get tags => List.unmodifiable(_tags);

  void init() {
    if (_tasks.isEmpty) {
      _generateDemoTasks();
    }
  }

  void _generateDemoTasks() {
    final random = Random();

    // 生成5个主任务
    for (int i = 1; i <= 5; i++) {
      final mainTaskId = 'task-$i';
      final mainTask = TaskItem(
        id: mainTaskId,
        title: '任务$i',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(10))),
        tags: [_tags[random.nextInt(_tags.length)]],
        group: _groups[random.nextInt(_groups.length)],
        priority: Priority.values[random.nextInt(Priority.values.length)],
        subtitle: random.nextBool() ? '任务$i的副标题' : null,
      );

      // 为每个主任务生成1-3个子任务
      final subTaskCount = random.nextInt(3) + 1;
      final subTaskIds = <String>[];

      for (int j = 1; j <= subTaskCount; j++) {
        final subTaskId = '$mainTaskId-sub-$j';
        subTaskIds.add(subTaskId);

        final subTask = TaskItem(
          id: subTaskId,
          title: '子任务$j',
          createdAt: DateTime.now().subtract(Duration(days: random.nextInt(5))),
          tags: random.nextBool() ? [_tags[random.nextInt(_tags.length)]] : [],
          group: mainTask.group,
          priority: Priority.values[random.nextInt(Priority.values.length)],
        );

        _tasks.add(subTask);
      }

      mainTask.subTaskIds = subTaskIds;
      _tasks.add(mainTask);
    }
  }

  List<TaskItem> getTasksByGroup(String group) {
    if (group.isEmpty) return tasks;
    return _tasks.where((task) => task.group == group).toList();
  }

  List<TaskItem> getMainTasks() {
    return _tasks
        .where((task) => !_tasks.any((t) => t.subTaskIds.contains(task.id)))
        .toList();
  }

  List<TaskItem> getSubTasks(String parentTaskId) {
    final parent = _tasks.firstWhere((task) => task.id == parentTaskId);
    return _tasks.where((task) => parent.subTaskIds.contains(task.id)).toList();
  }

  void addGroup(String group) {
    if (!_groups.contains(group)) {
      _groups.add(group);
    }
  }

  void removeGroup(String group) {
    _groups.remove(group);
    // 将该分组下的任务移到默认分组
    for (var task in _tasks.where((task) => task.group == group)) {
      task.group = '';
    }
  }

  void addTag(String tag) {
    if (!_tags.contains(tag)) {
      _tags.add(tag);
    }
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    // 从所有任务中移除该标签
    for (var task in _tasks) {
      task.tags.remove(tag);
    }
  }

  void addTask(TaskItem task) {
    _tasks.add(task);
  }

  void updateTask(TaskItem task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  void deleteTask(String taskId) {
    // 删除任务及其子任务
    final task = _tasks.firstWhere((t) => t.id == taskId);
    for (var subTaskId in task.subTaskIds) {
      _tasks.removeWhere((t) => t.id == subTaskId);
    }
    _tasks.removeWhere((t) => t.id == taskId);
  }

  // 向上移动任务
  void moveTaskUp(String taskId) {
    final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (currentIndex > 0) {
      final task = _tasks[currentIndex];
      _tasks.removeAt(currentIndex);
      _tasks.insert(currentIndex - 1, task);
    }
  }

  // 向下移动任务
  void moveTaskDown(String taskId) {
    final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (currentIndex < _tasks.length - 1) {
      final task = _tasks[currentIndex];
      _tasks.removeAt(currentIndex);
      _tasks.insert(currentIndex + 1, task);
    }
  }

  // 改变任务层级
  // 升级任务（变为父任务的同级任务）
  void moveTaskLevelUp(String taskId) {
    changeTaskLevel(taskId, true);
  }

  // 降级任务（变为上一个同级任务的子任务）
  void moveTaskLevelDown(String taskId) {
    changeTaskLevel(taskId, false);
  }

  void changeTaskLevel(String taskId, bool levelUp) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (levelUp) {
      // 升级：从当前父任务的子任务列表中移除
      final parentTask = _tasks.firstWhere(
        (t) => t.subTaskIds.contains(taskId),
        orElse: () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
      );
      if (parentTask.id.isNotEmpty) {
        parentTask.subTaskIds.remove(taskId);
      }
    } else {
      // 降级：添加到上一个同级任务的子任务列表中
      final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (currentIndex > 0) {
        final previousTask = _tasks[currentIndex - 1];
        if (!previousTask.subTaskIds.contains(taskId)) {
          previousTask.subTaskIds.add(taskId);
        }
      }
    }
  }
}
