import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../controllers/controllers.dart';
import 'task_form.dart';
import 'package:intl/intl.dart';

class TaskDetailView extends StatefulWidget {
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
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 创建一个定时器，每秒更新一次UI，以刷新计时器显示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.task.status == TaskStatus.inProgress &&
          widget.task.startTime != null) {
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
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(TodoLocalizations.of(context)!.taskDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TaskForm(
                        task: widget.task,
                        taskController: widget.taskController,
                        reminderController: widget.reminderController,
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
                builder:
                    (context) => AlertDialog(
                      title: Text(
                        TodoLocalizations.of(context)!.deleteTaskTitle,
                      ),
                      content: Text(
                        TodoLocalizations.of(context)!.deleteTaskMessage,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(AppLocalizations.of(context)!.delete),
                        ),
                      ],
                    ),
              );

              if (confirmed == true && context.mounted) {
                await widget.taskController.deleteTask(widget.task.id);
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
                    widget.task.statusIcon,
                    color:
                        widget.task.status == TaskStatus.done
                            ? Colors.green
                            : theme.disabledColor,
                  ),
                  onPressed: () {
                    final newStatus =
                        TaskStatus.values[(widget.task.status.index + 1) %
                            TaskStatus.values.length];
                    widget.taskController.updateTaskStatus(
                      widget.task.id,
                      newStatus,
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      decoration:
                          widget.task.status == TaskStatus.done
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
                    color: widget.task.priorityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 描述
            if (widget.task.description != null &&
                widget.task.description!.isNotEmpty) ...[
              Text(
                TodoLocalizations.of(context)!.description,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(widget.task.description!),
              const SizedBox(height: 16),
            ],

            // 标签
            if (widget.task.tags.isNotEmpty) ...[
              Text(
                TodoLocalizations.of(context)!.tags,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    widget.task.tags
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

            // 计时器信息
            Text(
              TodoLocalizations.of(context)!.timer,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TodoLocalizations.of(context)!.duration,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          widget.task.formattedDuration,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                widget.task.status == TaskStatus.inProgress
                                    ? theme.colorScheme.primary
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: Text(TodoLocalizations.of(context)!.start),
                          onPressed:
                              widget.task.status != TaskStatus.inProgress
                                  ? () {
                                    widget.taskController.updateTaskStatus(
                                      widget.task.id,
                                      TaskStatus.inProgress,
                                    );
                                    setState(() {});
                                  }
                                  : null,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: Text(TodoLocalizations.of(context)!.pause),
                          onPressed:
                              widget.task.status == TaskStatus.inProgress
                                  ? () {
                                    widget.taskController.updateTaskStatus(
                                      widget.task.id,
                                      TaskStatus.todo,
                                    );
                                    setState(() {});
                                  }
                                  : null,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(TodoLocalizations.of(context)!.complete),
                          onPressed:
                              widget.task.status != TaskStatus.done
                                  ? () {
                                    widget.taskController.updateTaskStatus(
                                      widget.task.id,
                                      TaskStatus.done,
                                    );
                                    setState(() {});
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 日期信息
            Text(
              TodoLocalizations.of(context)!.dates,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(TodoLocalizations.of(context)!.created),
                  subtitle: Text(dateFormat.format(widget.task.createdAt)),
                ),
                if (widget.task.dueDate != null)
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(TodoLocalizations.of(context)!.dueDate),
                    subtitle: Text(dateFormat.format(widget.task.dueDate!)),
                  ),
                const SizedBox(height: 16),
              ],
            ),

            // 子任务
            if (widget.task.subtasks.isNotEmpty) ...[
              Text(
                TodoLocalizations.of(context)!.subtasks,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.task.subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = widget.task.subtasks[index];
                  return CheckboxListTile(
                    value: subtask.isCompleted,
                    onChanged: (value) {
                      if (value != null) {
                        widget.taskController.updateSubtaskStatus(
                          widget.task.id,
                          subtask.id,
                          value,
                        );
                      }
                    },
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
            if (widget.task.reminders.isNotEmpty) ...[
              Text(
                TodoLocalizations.of(context)!.reminders,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.task.reminders.length,
                itemBuilder: (context, index) {
                  final reminder = widget.task.reminders[index];
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
