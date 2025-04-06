import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../services/todo_service.dart';

class TaskTreeView extends StatelessWidget {
  final TodoService todoService;
  final TaskItem? currentTask;
  final String? selectedTaskId;
  final Function(String) onTaskSelected;

  const TaskTreeView({
    super.key,
    required this.todoService,
    this.currentTask,
    this.selectedTaskId,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _getRootTasks().length,
      itemBuilder: (context, index) {
        return TaskTreeItem(
          task: _getRootTasks()[index],
          depth: 0,
          todoService: todoService,
          selectedTaskId: selectedTaskId,
          onTaskSelected: onTaskSelected,
        );
      },
    );
  }

  List<TaskItem> _getRootTasks() {
    // 获取所有子任务的ID
    final Set<String> allSubTaskIds = {};
    for (var task in todoService.tasks) {
      allSubTaskIds.addAll(task.subTaskIds);
    }

    // 过滤出顶级任务
    final rootTasks = todoService.tasks.where((task) {
      // 排除当前正在编辑的任务
      if (currentTask != null && task.id == currentTask!.id) {
        return false;
      }
      // 如果任务ID在子任务集合中，说明它不是顶级任务
      return !allSubTaskIds.contains(task.id);
    }).toList();

    // 按任务标题排序
    rootTasks.sort((a, b) => a.title.compareTo(b.title));
    return rootTasks;
  }
}

class TaskTreeItem extends StatelessWidget {
  final TaskItem task;
  final int depth;
  final TodoService todoService;
  final String? selectedTaskId;
  final Function(String) onTaskSelected;

  const TaskTreeItem({
    super.key,
    required this.task,
    required this.depth,
    required this.todoService,
    required this.selectedTaskId,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = task.subTaskIds.isNotEmpty;
    final children = _getChildTasks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onTaskSelected(task.id),
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 * depth,
              top: 8.0,
              bottom: 8.0,
              right: 16.0,
            ),
            decoration: BoxDecoration(
              color: selectedTaskId == task.id
                  ? Theme.of(context).primaryColor.withAlpha(30)
                  : null,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  hasChildren ? Icons.arrow_drop_down : Icons.circle,
                  size: hasChildren ? 24 : 8,
                  color: hasChildren
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: selectedTaskId == task.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedTaskId == task.id
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren) ...[
          const SizedBox(height: 4),
          ...children.map(
            (child) => TaskTreeItem(
              task: child,
              depth: depth + 1,
              todoService: todoService,
              selectedTaskId: selectedTaskId,
              onTaskSelected: onTaskSelected,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  List<TaskItem> _getChildTasks() {
    if (!task.subTaskIds.isNotEmpty) return [];
    return task.subTaskIds
        .map((id) => todoService.tasks.firstWhere((t) => t.id == id))
        .toList();
  }
}