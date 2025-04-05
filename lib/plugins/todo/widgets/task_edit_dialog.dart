import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/todo_service.dart';

class TaskEditDialog extends StatefulWidget {
  final TaskItem? task; // 如果为null，表示新建任务；否则表示编辑任务
  final String? parentTaskId; // 如果不为null，表示创建子任务

  const TaskEditDialog({Key? key, this.task, this.parentTaskId})
    : super(key: key);

  @override
  _TaskEditDialogState createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _notesController = TextEditingController();

  late String _group;
  late Priority _priority;
  late List<String> _selectedTags;
  DateTime? _startDate;
  DateTime? _dueDate;

  final TodoService _todoService = TodoService();

  @override
  void initState() {
    super.initState();

    // 如果是编辑任务，填充现有数据
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _subtitleController.text = widget.task!.subtitle ?? '';
      _notesController.text = widget.task!.notes ?? '';
      _group = widget.task!.group;
      _priority = widget.task!.priority;
      _selectedTags = List.from(widget.task!.tags);
      _startDate = widget.task!.startDate;
      _dueDate = widget.task!.dueDate;
    } else {
      // 新建任务，设置默认值
      _group =
          widget.parentTaskId != null
              ? _todoService.tasks
                  .firstWhere((t) => t.id == widget.parentTaskId)
                  .group
              : (_todoService.groups.isNotEmpty
                  ? _todoService.groups.first
                  : '');
      _priority = Priority.notImportantNotUrgent;
      _selectedTags = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewTask = widget.task == null;
    final isSubTask = widget.parentTaskId != null;
    final title = isNewTask ? (isSubTask ? '新建子任务' : '新建任务') : '编辑任务';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: '副标题（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _group,
                decoration: const InputDecoration(
                  labelText: '分组',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ..._todoService.groups.map(
                    (group) =>
                        DropdownMenuItem(value: group, child: Text(group)),
                  ),
                  if (!_todoService.groups.contains(''))
                    const DropdownMenuItem(value: '', child: Text('无分组')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _group = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: '优先级',
                  border: OutlineInputBorder(),
                ),
                items:
                    Priority.values.map((priority) {
                      String label;
                      switch (priority) {
                        case Priority.importantUrgent:
                          label = '重要且紧急';
                          break;
                        case Priority.importantNotUrgent:
                          label = '重要不紧急';
                          break;
                        case Priority.notImportantUrgent:
                          label = '紧急不重要';
                          break;
                        case Priority.notImportantNotUrgent:
                          label = '不重要不紧急';
                          break;
                      }
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(label),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTagsSelector(),
              const SizedBox(height: 16),
              _buildDateSelectors(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(isNewTask ? '创建' : '保存'),
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _todoService.tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开始日期', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                            : '未设置',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('截止日期', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.year}-${_dueDate!.month}-${_dueDate!.day}'
                            : '未设置',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _dueDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // 如果开始日期晚于截止日期，更新截止日期
          if (_dueDate != null && _startDate!.isAfter(_dueDate!)) {
            _dueDate = _startDate;
          }
        } else {
          _dueDate = pickedDate;
          // 如果截止日期早于开始日期，更新开始日期
          if (_startDate != null && _dueDate!.isBefore(_startDate!)) {
            _startDate = _dueDate;
          }
        }
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final subtitle = _subtitleController.text.trim();
      final notes = _notesController.text.trim();

      TaskItem task;

      if (widget.task != null) {
        // 编辑现有任务
        task = widget.task!.copyWith(
          title: title,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          notes: notes.isNotEmpty ? notes : null,
          group: _group,
          priority: _priority,
          tags: _selectedTags,
          startDate: _startDate,
          dueDate: _dueDate,
        );
        _todoService.updateTask(task);
      } else {
        // 创建新任务
        final newId = const Uuid().v4();
        task = TaskItem(
          id: newId,
          title: title,
          createdAt: DateTime.now(),
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          notes: notes.isNotEmpty ? notes : null,
          group: _group,
          priority: _priority,
          tags: _selectedTags,
          startDate: _startDate,
          dueDate: _dueDate,
        );
        _todoService.addTask(task);

        // 如果是子任务，更新父任务
        if (widget.parentTaskId != null) {
          final parentTask = _todoService.tasks.firstWhere(
            (t) => t.id == widget.parentTaskId,
          );
          parentTask.subTaskIds.add(task.id);
          _todoService.updateTask(parentTask);
        }
      }

      Navigator.of(context).pop(task);
    }
  }
}
