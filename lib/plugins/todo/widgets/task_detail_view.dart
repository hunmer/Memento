import 'package:flutter/material.dart';
import '../models/models.dart';
import '../controllers/controllers.dart';
import 'task_form.dart';
import 'package:intl/intl.dart';

class TaskDetailView extends StatelessWidget {
  final Task task;
  final TaskController taskController;
  final ReminderController reminderController;

  const TaskDetailView({
    super.key,
    required this.task,
    required this.taskController,
    required this.reminderController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskForm(
                    task: task,
                    taskController: taskController,
                    reminderController: reminderController,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await taskController.deleteTask(task.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务状态和标题
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    task.statusIcon,
                    color: task.status == TaskStatus.done
                        ? Colors.green
                        : theme.disabledColor,
                  ),
                  onPressed: () {
                    final newStatus = TaskStatus.values[
                        (task.status.index + 1) % TaskStatus.values.length];
                    taskController.updateTaskStatus(task.id, newStatus);
                  },
                ),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.priorityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 描述
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(task.description!),
              const SizedBox(height: 16),
            ],

            // 标签
            if (task.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: task.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue.shade100,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 日期信息
            Text(
              'Dates',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Created'),
                  subtitle: Text(dateFormat.format(task.createdAt)),
                ),
                if (task.dueDate != null)
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Due Date'),
                    subtitle: Text(dateFormat.format(task.dueDate!)),
                  ),
                const SizedBox(height: 16),
              ],
            ),

            // 子任务
            if (task.subtasks.isNotEmpty) ...[
              Text(
                'Subtasks',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = task.subtasks[index];
                  return CheckboxListTile(
                    value: subtask.isCompleted,
                    onChanged: (value) {
                      if (value != null) {
                        taskController.updateSubtaskStatus(
                          task.id,
                          subtask.id,
                          value,
                        );
                      }
                    },
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // 提醒
            if (task.reminders.isNotEmpty) ...[
              Text(
                'Reminders',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.reminders.length,
                itemBuilder: (context, index) {
                  final reminder = task.reminders[index];
                  return ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(dateFormat.format(reminder)),
                    subtitle: Text(timeFormat.format(reminder)),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}