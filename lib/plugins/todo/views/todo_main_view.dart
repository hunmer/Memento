import 'dart:io';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showTaskDetailDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  TodoLocalizations.of(context).description,
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
                  TodoLocalizations.of(context).tags,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: task.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.blue.shade100,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                TodoLocalizations.of(context).timer,
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
                  color: task.status == TaskStatus.inProgress
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
                    label: Text(TodoLocalizations.of(context).start),
                    onPressed: task.status != TaskStatus.inProgress
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
                    label: Text(TodoLocalizations.of(context).pause),
                    onPressed: task.status == TaskStatus.inProgress
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
                    label: Text(TodoLocalizations.of(context).complete),
                    onPressed: task.status != TaskStatus.done
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
            child: Text(TodoLocalizations.of(context).close),
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
            child: Text(TodoLocalizations.of(context).edit),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(TodoLocalizations.of(context).deleteTask),
                  content: Text(TodoLocalizations.of(context).confirmDeleteThisTask),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(TodoLocalizations.of(context).cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(TodoLocalizations.of(context).delete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _plugin.taskController.deleteTask(task.id);
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => PluginManager.toHomeScreen(context),
                ),
        title: Text(TodoLocalizations.of(context).name),
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
              NavigationHelper.push(context, HistoryCompletedView(
                        completedTasks: _plugin.taskController.completedTasks,
                        taskController: _plugin.taskController,),
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
                    child: Text(TodoLocalizations.of(context).sortByDueDate),
                  ),
                  PopupMenuItem(
                    value: SortBy.priority,
                    child: Text(TodoLocalizations.of(context).sortByPriority),
                  ),
                  PopupMenuItem(
                    value: SortBy.custom,
                    child: Text(TodoLocalizations.of(context).customSort),
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
                onTaskDismissed: (task) {
                  _plugin.taskController.deleteTask(task.id);
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
          NavigationHelper.push(context, TaskForm(
                    taskController: _plugin.taskController,
                    reminderController: _plugin.reminderController,),
          );
        },
      ),
    );
  }
}
