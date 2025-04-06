import 'dart:convert';
import '../models/task_item.dart';
import '../../../core/storage/storage_manager.dart';
import '../todo_plugin.dart';

class TodoService {
  static const String _storageKey = 'todo/tasks.json';
  static TodoService? _instance;
  static TodoService getInstance(StorageManager storage) {
    _instance ??= TodoService._internal();
    return _instance!;
  }

  TodoService._internal();

  final List<TaskItem> _tasks = [];
  final List<String> _groups = [];
  final List<String> _tags = [];

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<String> get groups => List.unmodifiable(_groups);
  List<String> get tags => List.unmodifiable(_tags);

  Future<void> init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (await TodoPlugin.instance.storage.fileExists(_storageKey)) {
        try {
          final data = await TodoPlugin.instance.storage.readJson(_storageKey);
          if (data != null) {
            final Map<String, dynamic> jsonData = data as Map<String, dynamic>;
            _tasks.clear();
            _tasks.addAll(
              (jsonData['tasks'] as List).map(
                (task) => TaskItem.fromJson(task as Map<String, dynamic>),
              ),
            );

            _groups.clear();
            _groups.addAll((jsonData['groups'] as List).cast<String>());

            _tags.clear();
            _tags.addAll((jsonData['tags'] as List).cast<String>());

            // 加载后同步所有任务的完成状态
            _syncAllTasksCompletionStatus();
          }
        } catch (e) {
          print('JSON parsing error: $e');
        }
      }
    } catch (e) {
      print('Failed to load todo data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final data = {
        'tasks': _tasks.map((task) => task.toJson()).toList(),
        'groups': _groups.toList(), // 确保转换为List
        'tags': _tags.toList(), // 确保转换为List
      };

      // 先验证JSON格式是否正确
      final jsonString = json.encode(data);
      json.decode(jsonString); // 验证JSON格式

      await TodoPlugin.instance.storage.writeJson(_storageKey, data);
    } catch (e) {
      print('Failed to save todo data: $e');
      // 如果保存失败，重置数据
      _tasks.clear();
      _groups.clear();
      _tags.clear();
    }
  }

  // _generateDemoTasks 方法已被移除

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

  Future<void> addGroup(String group) async {
    if (!_groups.contains(group)) {
      _groups.add(group);
      await _saveData();
    }
  }

  Future<void> removeGroup(String group) async {
    _groups.remove(group);
    // 将该分组下的任务移到默认分组
    for (var task in _tasks.where((task) => task.group == group)) {
      task.group = '';
    }
    await _saveData();
  }

  Future<void> addTag(String tag) async {
    if (!_tags.contains(tag)) {
      _tags.add(tag);
      await _saveData();
    }
  }

  Future<void> removeTag(String tag) async {
    _tags.remove(tag);
    // 从所有任务中移除该标签
    for (var task in _tasks) {
      task.tags.remove(tag);
    }
    await _saveData();
  }

  Future<void> addTask(TaskItem task) async {
    _tasks.add(task);
    // 如果有父任务ID，更新父任务的子任务列表
    if (task.parentTaskId != null && task.parentTaskId!.isNotEmpty) {
      final parentTask = _tasks.firstWhere(
        (t) => t.id == task.parentTaskId,
        orElse: () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
      );
      if (parentTask.id.isNotEmpty) {
        // 使用Set去重，确保不会添加重复的子任务ID
        final updatedSubTaskIds = {...parentTask.subTaskIds, task.id}.toList();
        final updatedParent = parentTask.copyWith(
          subTaskIds: updatedSubTaskIds,
        );
        await updateTask(updatedParent);
      }
    }
    await _saveData();
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final oldTask = _tasks[index];
      _tasks[index] = task;

      // 如果父任务ID发生变化，需要更新新旧父任务的子任务列表
      if (oldTask.parentTaskId != task.parentTaskId) {
        // 从旧父任务中移除
        if (oldTask.parentTaskId != null && oldTask.parentTaskId!.isNotEmpty) {
          final oldParent = _tasks.firstWhere(
            (t) => t.id == oldTask.parentTaskId,
            orElse:
                () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
          );
          if (oldParent.id.isNotEmpty) {
            final updatedOldParent = oldParent.copyWith(
              subTaskIds:
                  oldParent.subTaskIds.where((id) => id != task.id).toList(),
            );
            await updateTask(updatedOldParent);
          }
        }

        // 添加到新父任务
        if (task.parentTaskId != null && task.parentTaskId!.isNotEmpty) {
          final newParent = _tasks.firstWhere(
            (t) => t.id == task.parentTaskId,
            orElse:
                () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
          );
          if (newParent.id.isNotEmpty) {
            final updatedNewParent = newParent.copyWith(
              subTaskIds: [...newParent.subTaskIds, task.id],
            );
            await updateTask(updatedNewParent);
          }
        }
      }

      // 同步父子任务的完成状态
      await _syncTaskCompletionStatus(task.id);
      await _saveData();
    }
  }

  // 同步所有任务的完成状态
  void _syncAllTasksCompletionStatus() {
    // 从子任务开始同步，确保父任务状态正确
    final mainTasks = getMainTasks();
    for (var task in mainTasks) {
      _syncTaskCompletionStatusWithoutSave(task.id);
    }
  }

  // 同步指定任务的完成状态（包括保存）
  Future<void> _syncTaskCompletionStatus(String taskId) async {
    _syncTaskCompletionStatusWithoutSave(taskId);
    await _saveData();
  }

  // 同步指定任务的完成状态（不保存）
  void _syncTaskCompletionStatusWithoutSave(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);

    if (task.subTaskIds.isNotEmpty) {
      // 如果是父任务，根据子任务状态更新完成状态
      final subTasks = getSubTasks(taskId);
      final allSubTasksCompleted = subTasks.every((t) => t.isCompleted);
      final anySubTaskCompleted = subTasks.any((t) => t.isCompleted);

      // 只有所有子任务完成时，父任务才算完成
      task.isCompleted = allSubTasksCompleted;

      // 如果有部分子任务完成，设置父任务为部分完成状态
      task.isPartiallyCompleted = anySubTaskCompleted && !allSubTasksCompleted;
    } else {
      // 如果是子任务，更新父任务的状态
      final parentTask = _tasks.firstWhere(
        (t) => t.subTaskIds.contains(taskId),
        orElse: () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
      );

      if (parentTask.id.isNotEmpty) {
        final allSubTasksCompleted = getSubTasks(
          parentTask.id,
        ).every((t) => t.isCompleted);
        final anySubTaskCompleted = getSubTasks(
          parentTask.id,
        ).any((t) => t.isCompleted);

        parentTask.isCompleted = allSubTasksCompleted;
        parentTask.isPartiallyCompleted =
            anySubTaskCompleted && !allSubTasksCompleted;
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    // 找到要删除的任务
    final task = _tasks.firstWhere((t) => t.id == taskId);

    // 找到父任务（如果存在）
    final parentTask = _tasks.firstWhere(
      (t) => t.subTaskIds.contains(taskId),
      orElse: () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
    );

    // 删除任务及其子任务
    for (var subTaskId in task.subTaskIds) {
      _tasks.removeWhere((t) => t.id == subTaskId);
    }
    _tasks.removeWhere((t) => t.id == taskId);

    // 如果存在父任务，更新其状态
    if (parentTask.id.isNotEmpty) {
      await _syncTaskCompletionStatus(parentTask.id);
    }

    await _saveData();
  }

  // 向上移动任务
  Future<void> moveTaskUp(String taskId) async {
    final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (currentIndex > 0) {
      final task = _tasks[currentIndex];
      _tasks.removeAt(currentIndex);
      _tasks.insert(currentIndex - 1, task);
      await _saveData();
    }
  }

  // 向下移动任务
  Future<void> moveTaskDown(String taskId) async {
    final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (currentIndex < _tasks.length - 1) {
      final task = _tasks[currentIndex];
      _tasks.removeAt(currentIndex);
      _tasks.insert(currentIndex + 1, task);
      await _saveData();
    }
  }

  // 改变任务层级
  // 升级任务（变为父任务的同级任务）
  Future<void> moveTaskLevelUp(String taskId) async {
    await changeTaskLevel(taskId, true);
  }

  // 降级任务（变为上一个同级任务的子任务）
  Future<void> moveTaskLevelDown(String taskId) async {
    await changeTaskLevel(taskId, false);
  }

  Future<void> changeTaskLevel(String taskId, bool levelUp) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (levelUp) {
      // 升级：从当前父任务的子任务列表中移除
      final parentTask = _tasks.firstWhere(
        (t) => t.subTaskIds.contains(taskId),
        orElse: () => TaskItem(id: '', title: '', createdAt: DateTime.now()),
      );
      if (parentTask.id.isNotEmpty) {
        parentTask.subTaskIds.remove(taskId);
        await _saveData();
      }
    } else {
      // 降级：添加到上一个同级任务的子任务列表中
      final currentIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (currentIndex > 0) {
        final previousTask = _tasks[currentIndex - 1];
        if (!previousTask.subTaskIds.contains(taskId)) {
          // 使用Set去重并创建新的列表实例
          final updatedSubTaskIds =
              {...previousTask.subTaskIds, taskId}.toList();
          final updatedTask = previousTask.copyWith(
            subTaskIds: updatedSubTaskIds,
          );
          await updateTask(updatedTask);
        }
      }
    }
  }
}
