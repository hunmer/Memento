import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/todo_service.dart';
import '../../plugin_widget.dart';
import 'task_edit_dialog/task_form_fields.dart';
import 'task_edit_dialog/date_selector.dart';
import 'task_edit_dialog/parent_task_selector.dart';

class TaskEditDialog extends StatelessWidget {
  final TaskItem? task;
  final String? parentTaskId;

  const TaskEditDialog({super.key, this.task, this.parentTaskId});

  @override
  Widget build(BuildContext context) {
    final String dialogTitle =
        parentTaskId != null ? "新建子任务" : (task != null ? "编辑任务" : "新建任务");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
            child: Row(
              children: [
                Text(
                  dialogTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: TaskEditDialogContent(
                  task: task,
                  parentTaskId: parentTaskId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskEditDialogContent extends StatefulWidget {
  final TaskItem? task;
  final String? parentTaskId;

  const TaskEditDialogContent({super.key, this.task, this.parentTaskId});

  @override
  State<TaskEditDialogContent> createState() => TaskEditDialogState();
}

class TaskEditDialogState extends State<TaskEditDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _notesController = TextEditingController();

  late String group;
  late Priority priority;
  late List<String> selectedTags;
  DateTime? _startDate;
  DateTime? _dueDate;
  String? _parentTaskId;

  late final TodoService _todoService;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final pluginWidget = PluginWidget.of(context);
      if (pluginWidget == null) {
        throw Exception('TaskEditDialog must be a child of a PluginWidget');
      }
      _todoService = TodoService.getInstance(pluginWidget.plugin.storage);
      _isInitialized = true;

      _parentTaskId = widget.parentTaskId ?? widget.task?.parentTaskId;
      _initializeFields();
    }
  }

  void _initializeFields() {
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _subtitleController.text = widget.task!.subtitle ?? '';
      _notesController.text = widget.task!.notes ?? '';
      group = widget.task!.group;
      priority = widget.task!.priority;
      selectedTags = List.from(widget.task!.tags);
      _startDate = widget.task!.startDate;
      _dueDate = widget.task!.dueDate;
    } else {
      final defaultGroup =
          _todoService.groups.isNotEmpty ? _todoService.groups.first : '';
      group =
          widget.parentTaskId != null
              ? _todoService.tasks
                      .where((t) => t.id == widget.parentTaskId)
                      .map((t) => t.group)
                      .firstOrNull ??
                  defaultGroup
              : defaultGroup;
      priority = Priority.notImportantNotUrgent;
      selectedTags = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showParentTaskSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ParentTaskSelectionDialog(
            todoService: _todoService,
            currentTask: widget.task,
            selectedTaskId: _parentTaskId,
            onTaskSelected: (taskId) {
              setState(() {
                _parentTaskId = taskId;
              });
            },
          ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_dueDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final taskId = widget.task?.id ?? const Uuid().v4();
    final newTask = TaskItem(
      id: taskId,
      title: _titleController.text,
      subtitle: _subtitleController.text,
      notes: _notesController.text,
      group: group,
      priority: priority,
      tags: selectedTags,
      startDate: _startDate,
      dueDate: _dueDate,
      parentTaskId: _parentTaskId,
      subTaskIds: widget.task?.subTaskIds ?? [],
      completedAt: widget.task?.completedAt,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    try {
      // 如果是新任务（没有ID），使用addTask；否则使用updateTask
      if (widget.task == null || widget.task!.id.isEmpty) {
        await _todoService.addTask(newTask);
      } else {
        await _todoService.updateTask(newTask);
      }

      if (mounted) {
        // 确保 widget 仍然挂载
        // 使用 Future.microtask 来确保在下一个微任务中执行导航操作
        // 返回 TaskItem 对象
        Future.microtask(() => Navigator.of(context).pop(newTask));
      }
    } catch (e) {
      if (mounted) {
        // 确保 widget 仍然挂载
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskFormFields(
                titleController: _titleController,
                subtitleController: _subtitleController,
                notesController: _notesController,
                group: group,
                priority: priority,
                selectedTags: selectedTags,
                todoService: _todoService,
                onGroupChanged: (value) => setState(() => group = value),
                onPriorityChanged: (value) => setState(() => priority = value),
                onTagSelected:
                    (tag, selected) => setState(() {
                      if (selected) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
              ),
              const SizedBox(height: 16),
              ParentTaskSelector(
                parentTaskId: _parentTaskId,
                todoService: _todoService,
                onShowSelectionDialog: _showParentTaskSelectionDialog,
              ),
              const SizedBox(height: 16),
              DateSelector(
                startDate: _startDate,
                dueDate: _dueDate,
                onSelectDate: _selectDate,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: Text(widget.task == null ? '创建' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
