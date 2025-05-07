import 'package:flutter/material.dart';
import '../controllers/controllers.dart';
import '../controllers/task_controller.dart'; // 直接导入以获取 SortBy 枚举
import 'task_list_view.dart';
import 'task_grid_view.dart';
import 'add_task_button.dart';
import 'task_detail_view.dart';
import 'task_form.dart';
import 'filter_dialog.dart';

class TodoMainView extends StatelessWidget {
  final TaskController taskController;
  final ReminderController reminderController;

  const TodoMainView({
    Key? key,
    required this.taskController,
    required this.reminderController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        actions: [
          // 过滤按钮
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final tags = taskController.tasks
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
                taskController.applyFilter(filter);
              }
            },
          ),
          // 切换视图按钮
          IconButton(
            icon: Icon(
              taskController.isGridView ? Icons.view_list : Icons.grid_view,
            ),
            onPressed: taskController.toggleViewMode,
          ),
          // 排序按钮
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: taskController.setSortBy,
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
        animation: taskController,
        builder: (context, _) {
          return taskController.isGridView
              ? TaskGridView(
                  tasks: taskController.tasks,
                  onTaskTap: (task) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(
                          task: task,
                          taskController: taskController,
                          reminderController: reminderController,
                        ),
                      ),
                    );
                  },
                  onTaskStatusChanged: (task, status) {
                    taskController.updateTaskStatus(task.id, status);
                  },
                )
              : TaskListView(
                  tasks: taskController.tasks,
                  onTaskTap: (task) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(
                          task: task,
                          taskController: taskController,
                          reminderController: reminderController,
                        ),
                      ),
                    );
                  },
                  onTaskStatusChanged: (task, status) {
                    taskController.updateTaskStatus(task.id, status);
                  },
                  onTaskDismissed: (task) {
                    taskController.deleteTask(task.id);
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
                taskController: taskController,
                reminderController: reminderController,
              ),
            ),
          );
        },
      ),
    );
  }
}