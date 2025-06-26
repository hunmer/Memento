import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../controllers/controllers.dart';

class TaskForm extends StatefulWidget {
  final Task? task; // 如果为null，则是创建新任务
  final TaskController taskController;
  final ReminderController reminderController;

  const TaskForm({
    super.key,
    this.task,
    required this.taskController,
    required this.reminderController,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _startDate;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  late List<String> _tags;
  late List<Subtask> _subtasks;
  late List<DateTime> _reminders;
  late TextEditingController _subtaskController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _startDate = widget.task?.startDate;
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? TaskPriority.medium;

    // 初始化标签
    _tags = widget.task?.tags.toList() ?? [];

    _subtasks = widget.task?.subtasks.toList() ?? [];
    _reminders = widget.task?.reminders.toList() ?? [];
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _startDate != null && _dueDate != null
              ? DateTimeRange(start: _startDate!, end: _dueDate!)
              : DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 7)),
              ),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _dueDate = picked.end;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _dueDate = null;
    });
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(
          Subtask(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _subtaskController.text,
          ),
        );
        _subtaskController.clear();
      });
    }
  }

  void _toggleSubtask(int index) {
    setState(() {
      _subtasks[index].isCompleted = !_subtasks[index].isCompleted;
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Future<void> _addReminder() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      DateTime reminderDate = _dueDate ?? now;
      reminderDate = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // 如果设置的时间已经过去，则设置为明天同一时间
      if (reminderDate.isBefore(now)) {
        reminderDate = reminderDate.add(const Duration(days: 1));
      }

      setState(() {
        _reminders.add(reminderDate);
      });
    }
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TodoLocalizations.of(context)!.pleaseEnterTitle),
        ),
      );
      return;
    }

    if (widget.task == null) {
      // 创建新任务
      await widget.taskController.createTask(
        title: _titleController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        startDate: _startDate,
        dueDate: _dueDate,
        priority: _priority,
        tags: _tags,
        subtasks: _subtasks,
        reminders: _reminders,
      );
    } else {
      // 更新现有任务
      final updatedTask = Task(
        id: widget.task!.id,
        title: _titleController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        createdAt: widget.task!.createdAt,
        startDate: _startDate,
        dueDate: _dueDate,
        priority: _priority,
        status: widget.task!.status,
        tags: _tags,
        subtasks: _subtasks,
        reminders: _reminders,
      );
      await widget.taskController.updateTask(updatedTask);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null
              ? TodoLocalizations.of(context)!.newTask
              : TodoLocalizations.of(context)!.editTask,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveTask),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: TodoLocalizations.of(context)!.title,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 描述
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: TodoLocalizations.of(context)!.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 日期范围
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${TodoLocalizations.of(context)!.startDate}: ${_startDate == null ? TodoLocalizations.of(context)!.notSet : '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${TodoLocalizations.of(context)!.dueDate}: ${_dueDate == null ? TodoLocalizations.of(context)!.notSet : '${_dueDate!.year}/${_dueDate!.month}/${_dueDate!.day}'}',
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDateRange(context),
                  child: Text(TodoLocalizations.of(context)!.selectDates),
                ),
                if (_startDate != null || _dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDateRange,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 优先级
            Text(TodoLocalizations.of(context)!.priority),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: [
                ButtonSegment<TaskPriority>(
                  value: TaskPriority.low,
                  label: Text(TodoLocalizations.of(context)!.low),
                  icon: const Icon(Icons.arrow_downward),
                ),
                ButtonSegment<TaskPriority>(
                  value: TaskPriority.medium,
                  label: Text(TodoLocalizations.of(context)!.medium),
                  icon: const Icon(Icons.remove),
                ),
                ButtonSegment<TaskPriority>(
                  value: TaskPriority.high,
                  label: Text(TodoLocalizations.of(context)!.high),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (Set<TaskPriority> newSelection) {
                setState(() {
                  _priority = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // 标签
            Text(TodoLocalizations.of(context)!.tags),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ..._tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(TodoLocalizations.of(context)!.addTag),
                  onPressed: () {
                    _showAddTagDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 子任务
            Text(
              TodoLocalizations.of(context)!.subtasks,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: InputDecoration(
                      labelText:
                          '${TodoLocalizations.of(context)!.add} ${TodoLocalizations.of(context)!.subtasks.toLowerCase()}',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addSubtask),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subtasks.length,
              itemBuilder: (context, index) {
                final subtask = _subtasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: subtask.isCompleted,
                    onChanged: (_) => _toggleSubtask(index),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeSubtask(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 提醒
            Text(
              TodoLocalizations.of(context)!.reminders,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: Text(TodoLocalizations.of(context)!.addReminder),
              onPressed: _addReminder,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(
                    '${reminder.year}/${reminder.month}/${reminder.day} ${reminder.hour}:${reminder.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeReminder(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 显示添加标签对话框
  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(TodoLocalizations.of(context)!.addTag),
            content: TextField(
              controller: tagController,
              decoration: InputDecoration(
                labelText:
                    '${TodoLocalizations.of(context)!.tags} ${TodoLocalizations.of(context)!.title.toLowerCase()}',
                hintText:
                    '${TodoLocalizations.of(context)!.pleaseEnterTitle.toLowerCase()} ${TodoLocalizations.of(context)!.tags.toLowerCase()}',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  final tagName = tagController.text.trim();
                  if (tagName.isNotEmpty && !_tags.contains(tagName)) {
                    setState(() {
                      _tags.add(tagName);
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text(TodoLocalizations.of(context)!.add),
              ),
            ],
          ),
    );
  }
}
