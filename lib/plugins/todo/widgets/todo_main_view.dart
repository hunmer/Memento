import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../controllers/controllers.dart';
import '../controllers/task_controller.dart'; // 直接导入以获取 SortBy 枚举
import '../models/models.dart';
import 'task_list_view.dart';
import 'task_grid_view.dart';
import 'add_task_button.dart';
import 'task_detail_view.dart';
import 'task_form.dart';
import 'filter_dialog.dart';
import 'history_completed_view.dart';

class TodoMainView extends StatefulWidget {
  final TaskController taskController;
  final ReminderController reminderController;

  const TodoMainView({
    super.key,
    required this.taskController,
    required this.reminderController,
  });

  @override
  State<TodoMainView> createState() => _TodoMainViewState();
}

class _TodoMainViewState extends State<TodoMainView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 创建一个定时器，每秒更新一次UI，以刷新计时器显示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 检查是否有正在计时的任务
      bool hasActiveTimer = false;
      for (final task in widget.taskController.tasks) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        actions: [
          // 过滤按钮
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final tags = widget.taskController.tasks
                  .expand((task) => task.tags)
                  .toSet()
                  .toList();
              final filter = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => FilterDialog(
                  onFilter: (filter) => Navigator.pop(context, filter),
                  availableTags: tags,
                ),
              );
              if (filter != null) {
                widget.taskController.applyFilter(filter);
              }
            },
          ),
          // 切换视图按钮
          IconButton(
            icon: Icon(
              widget.taskController.isGridView ? Icons.view_list : Icons.grid_view,
            ),
            onPressed: widget.taskController.toggleViewMode,
          ),
          // 历史完成按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryCompletedView(
                    completedTasks: widget.taskController.completedTasks,
                    taskController: widget.taskController,
                  ),
                ),
              );
            },
          ),
          // 排序按钮
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: widget.taskController.setSortBy,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortBy.dueDate,
                child: Text('Sort by Due Date'),
              ),
              const PopupMenuItem(
                value: SortBy.priority,
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem(
                value: SortBy.custom,
                child: Text('Custom Sort'),
              ),
            ],
          ),
        ],
      ),
      // 主视图
      body: AnimatedBuilder(
        animation: widget.taskController,
        builder: (context, _) {
          return widget.taskController.isGridView
              ? TaskGridView(
                  tasks: widget.taskController.tasks,
                  onTaskTap: (task) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(
                          task: task,
                          taskController: widget.taskController,
                          reminderController: widget.reminderController,
                        ),
                      ),
                    );
                  },
                  onTaskStatusChanged: (task, status) {
                    widget.taskController.updateTaskStatus(task.id, status);
                  },
                )
              : TaskListView(
                  tasks: widget.taskController.tasks,
                  onTaskTap: (task) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(
                          task: task,
                          taskController: widget.taskController,
                          reminderController: widget.reminderController,
                        ),
                      ),
                    );
                  },
                  onTaskStatusChanged: (task, status) {
                    widget.taskController.updateTaskStatus(task.id, status);
                  },
                  onTaskDismissed: (task) {
                    widget.taskController.deleteTask(task.id);
                  },
                );
        },
      ),
      // 添加任务按钮
      floatingActionButton: AddTaskButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskForm(
                taskController: widget.taskController,
                reminderController: widget.reminderController,
              ),
            ),
          );
        },
      ),
    );
  }
}