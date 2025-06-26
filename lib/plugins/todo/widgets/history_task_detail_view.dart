import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class HistoryTaskDetailView extends StatelessWidget {
  final Task task;

  const HistoryTaskDetailView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(TodoLocalizations.of(context)!.completedTaskDetailsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务状态和标题
            Row(
              children: [
                Icon(task.statusIcon, color: Colors.green, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(task.title, style: theme.textTheme.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 完成日期
            Text(
              'Completed on: ${dateFormat.format(task.completedDate!)}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // 描述
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(task.description!),
              const SizedBox(height: 16),
            ],

            // 标签
            if (task.tags.isNotEmpty) ...[
              Text('Tags', style: theme.textTheme.titleMedium),
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

            // 日期信息
            Text('Dates', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(TodoLocalizations.of(context)!.created),
                  subtitle: Text(dateFormat.format(task.createdAt)),
                ),
                if (task.dueDate != null)
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(TodoLocalizations.of(context)!.dueDate),
                    subtitle: Text(dateFormat.format(task.dueDate!)),
                  ),
                const SizedBox(height: 16),
              ],
            ),

            // 子任务
            if (task.subtasks.isNotEmpty) ...[
              Text('Subtasks', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = task.subtasks[index];
                  return ListTile(
                    leading: Icon(
                      subtask.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          subtask.isCompleted
                              ? Colors.green
                              : theme.disabledColor,
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration:
                            subtask.isCompleted
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
              Text('Reminders', style: theme.textTheme.titleMedium),
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
