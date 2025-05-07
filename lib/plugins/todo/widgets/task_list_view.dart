import 'package:flutter/material.dart';
import '../models/models.dart';
import 'task_list_item.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onTaskStatusChanged;
  final Function(Task) onTaskDismissed;

  const TaskListView({
    Key? key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskStatusChanged,
    required this.onTaskDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet\nTap + to add a new task',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) => onTaskDismissed(task),
          child: TaskListItem(
            task: task,
            onTap: () => onTaskTap(task),
            onStatusChanged: (status) => onTaskStatusChanged(task, status),
          ),
        );
      },
    );
  }
}