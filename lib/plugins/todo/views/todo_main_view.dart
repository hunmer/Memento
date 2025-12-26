import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'dart:async';
import 'package:Memento/plugins/todo/controllers/controllers.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/plugins/todo/views/todo_four_quadrant_view.dart';
import 'package:Memento/plugins/todo/widgets/task_list_view.dart';
import 'package:Memento/plugins/todo/widgets/add_task_button.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/plugins/todo/widgets/filter_dialog.dart';
import 'package:Memento/plugins/todo/widgets/history_completed_view.dart';

class TodoMainView extends StatefulWidget {
  const TodoMainView({super.key});

  @override
  State<TodoMainView> createState() => _TodoMainViewState();
}

class _TodoMainViewState extends State<TodoMainView> {
  late TodoPlugin _plugin;
  Timer? _timer;
  // 在 initState 中直接注册事件监听，确保在 build 之前就准备好
  final List<(String eventName, void Function(EventArgs) handler)>
  _eventSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;

    // 在 initState 中注册事件监听，确保在 build 之前就准备好
    _registerTaskEventListeners();

    // 创建一个定时器，每秒更新一次UI，以刷新计时器显示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 检查是否有正在计时的任务
      bool hasActiveTimer = false;
      for (final task in _plugin.taskController.tasks) {
        if (task.status == TaskStatus.inProgress && task.startTime != null) {
          hasActiveTimer = true;
          break;
        }
      }

      // 只有在有活动计时器时才刷新UI
      if (hasActiveTimer) {
        setState(() {});
      }
    });
  }

  /// 在 initState 中注册任务事件监听器，确保在 build 之前就订阅
  void _registerTaskEventListeners() {
    final events = [
      'task_added',
      'task_updated',
      'task_deleted',
      'task_completed',
    ];
    for (final event in events) {
      void handler(EventArgs args) {
        if (kDebugMode) {
          print('[TodoMainView] received event: "$event"');
        }
        if (mounted) {
          setState(() {});
        }
      }

      EventManager.instance.subscribe(event, handler);
      _eventSubscriptions.add((event, handler));
      if (kDebugMode) {
        print('[TodoMainView] subscribed to: "$event"');
      }
    }
  }

  @override
  void dispose() {
    // 取消所有事件监听
    for (final (eventName, handler) in _eventSubscriptions) {
      EventManager.instance.unsubscribe(eventName, handler);
    }
    _eventSubscriptions.clear();
    _timer?.cancel();
    super.dispose();
  }

  void _showTaskDetailDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(task.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    Text(
                      'todo_description'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(task.description!),
                    const SizedBox(height: 16),
                  ],
                  if (task.tags.isNotEmpty) ...[
                    Text(
                      'todo_tags'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          task.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.blue.shade100,
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'todo_timer'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.formattedDuration,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          task.status == TaskStatus.inProgress
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text('todo_start'.tr),
                        onPressed:
                            task.status != TaskStatus.inProgress
                                ? () {
                                  _plugin.taskController.updateTaskStatus(
                                    task.id,
                                    TaskStatus.inProgress,
                                  );
                                  Navigator.of(context).pop();
                                }
                                : null,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pause),
                        label: Text('todo_pause'.tr),
                        onPressed:
                            task.status == TaskStatus.inProgress
                                ? () {
                                  _plugin.taskController.updateTaskStatus(
                                    task.id,
                                    TaskStatus.todo,
                                  );
                                  Navigator.of(context).pop();
                                }
                                : null,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text('todo_complete'.tr),
                        onPressed:
                            task.status != TaskStatus.done
                                ? () {
                                  _plugin.taskController.updateTaskStatus(
                                    task.id,
                                    TaskStatus.done,
                                  );
                                  Navigator.of(context).pop();
                                }
                                : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('todo_close'.tr),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  NavigationHelper.push(
                    context,
                    TaskForm(
                      task: task,
                      taskController: _plugin.taskController,
                      reminderController: _plugin.reminderController,
                    ),
                  );
                },
                child: Text('todo_edit'.tr),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('todo_deleteTask'.tr),
                          content: Text('todo_confirmDeleteThisTask'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('todo_cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('todo_delete'.tr),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true) {
                    await _plugin.taskController.deleteTask(task.id);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => PluginManager.toHomeScreen(context),
                ),
        title: Text('todo_name'.tr),
        actions: [
          // 过滤按钮
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final tags =
                  _plugin.taskController.tasks
                      .expand((task) => task.tags)
                      .toSet()
                      .toList();
              final filter = await showDialog<Map<String, dynamic>>(
                context: context,
                builder:
                    (context) => FilterDialog(
                      onFilter: (filter) => Navigator.pop(context, filter),
                      availableTags: tags,
                    ),
              );
              if (filter != null) {
                _plugin.taskController.applyFilter(filter);
              }
            },
          ),
          // 切换视图按钮
          IconButton(
            icon: Icon(
              _plugin.taskController.isGridView
                  ? Icons.view_list
                  : Icons.dashboard,
            ),
            onPressed: _plugin.taskController.toggleViewMode,
          ),
          // 历史完成按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              NavigationHelper.push(
                context,
                HistoryCompletedView(
                  completedTasks: _plugin.taskController.completedTasks,
                  taskController: _plugin.taskController,
                ),
              );
            },
          ),
          // 排序按钮
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: _plugin.taskController.setSortBy,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: SortBy.dueDate,
                    child: Text('todo_sortByDueDate'.tr),
                  ),
                  PopupMenuItem(
                    value: SortBy.priority,
                    child: Text('todo_sortByPriority'.tr),
                  ),
                  PopupMenuItem(
                    value: SortBy.custom,
                    child: Text('todo_customSort'.tr),
                  ),
                ],
          ),
        ],
      ),
      // 主视图
      body: AnimatedBuilder(
        animation: _plugin.taskController,
        builder: (context, _) {
          return _plugin.taskController.isGridView
              ? TodoFourQuadrantView(
                tasks: _plugin.taskController.tasks,
                onTaskTap: (task) => _showTaskDetailDialog(context, task),
                onTaskStatusChanged: (task, status) {
                  _plugin.taskController.updateTaskStatus(task.id, status);
                },
              )
              : TaskListView(
                tasks: _plugin.taskController.tasks,
                onTaskTap: (task) => _showTaskDetailDialog(context, task),
                onTaskStatusChanged: (task, status) {
                  _plugin.taskController.updateTaskStatus(task.id, status);
                },
                onTaskDismissed: (task) async {
                  await _plugin.taskController.deleteTask(task.id);
                },
                onTaskEdit: (task) {
                  NavigationHelper.push(
                    context,
                    TaskForm(
                      task: task,
                      taskController: _plugin.taskController,
                      reminderController: _plugin.reminderController,
                    ),
                  );
                },
                onSubtaskStatusChanged: (taskId, subtaskId, isCompleted) {
                  _plugin.taskController.updateSubtaskStatus(
                    taskId,
                    subtaskId,
                    isCompleted,
                  );
                },
              );
        },
      ),
      // 添加任务按钮
      floatingActionButton: AddTaskButton(
        onPressed: () {
          NavigationHelper.push(
            context,
            TaskForm(
              taskController: _plugin.taskController,
              reminderController: _plugin.reminderController,
            ),
          );
        },
      ),
    );
  }
}
