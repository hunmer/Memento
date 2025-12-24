import 'package:get/get.dart';
import 'package:Memento/widgets/picker/icon_picker_dialog.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/plugins/todo/controllers/controllers.dart';
import 'package:Memento/core/route/route_history_manager.dart';

class TaskForm extends StatefulWidget {
  final Task? task; // If null, create new task
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
  late TextEditingController _notesController; // Mapped to description
  late DateTime? _startDate;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  late List<String> _tags;
  late List<Subtask> _subtasks;
  late List<DateTime> _reminders;
  late TextEditingController _subtaskController;
  late IconData? _icon;

  // Custom color from HTML
  static const Color _primaryColor = Color(0xFF607AFB);
  static const Color _backgroundLight = Color(0xFFF5F6F8);
  static const Color _backgroundDark = Color(0xFF0F1323);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _startDate = widget.task?.startDate;
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _tags = widget.task?.tags.toList() ?? [];
    _subtasks = widget.task?.subtasks.toList() ?? [];
    _reminders = widget.task?.reminders.toList() ?? [];
    _subtaskController = TextEditingController();
    _icon = widget.task?.icon ?? Icons.assignment; // 默认使用任务图标

    // 更新路由上下文，使"询问当前上下文"功能能获取到当前页面状态
    _updateRouteContext();
  }

  /// 更新路由上下文
  void _updateRouteContext() {
    final isEditing = widget.task != null;
    RouteHistoryManager.updateCurrentContext(
      pageId: isEditing ? '/todo_form_edit' : '/todo_form_new',
      title: isEditing ? '编辑待办 - ${widget.task!.title}' : '新建待办',
      params: {
        'mode': isEditing ? 'edit' : 'new',
        if (isEditing) 'taskId': widget.task!.id,
        if (isEditing) 'taskTitle': widget.task!.title,
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Theme.of(context).brightness),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure due date is not before start date
        if (_dueDate != null && _dueDate!.isBefore(picked)) {
          _dueDate = null;
        }
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Theme.of(context).brightness),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(
          Subtask(
            id: const Uuid().v4(),
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
    final DateTime baseDate = _dueDate ?? DateTime.now();
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime.now(),
      lastDate: baseDate.add(const Duration(days: 365)),
       builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Theme.of(context).brightness),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
         builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Theme.of(context).brightness),
          ),
          child: child!,
        );
      },
      );

      if (pickedTime != null) {
         final reminderDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _reminders.add(reminderDateTime);
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      Toast.error('todo_pleaseEnterTitle'.tr);
      return;
    }

    // Ensure pending subtask text is added
    if (_subtaskController.text.isNotEmpty) {
       _addSubtask();
    }

    if (widget.task == null) {
      await widget.taskController.createTask(
        title: _titleController.text,
        description:
            _notesController.text.isEmpty
                ? null
                : _notesController.text,
        startDate: _startDate,
        dueDate: _dueDate,
        priority: _priority,
        tags: _tags,
        subtasks: _subtasks,
        reminders: _reminders,
        icon: _icon,
      );
    } else {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text,
        description:
            _notesController.text.isEmpty
                ? null
                : _notesController.text,
        startDate: _startDate,
        dueDate: _dueDate,
        priority: _priority,
        tags: _tags,
        subtasks: _subtasks,
        reminders: _reminders,
        icon: _icon,
      );
      await widget.taskController.updateTask(updatedTask);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // --- Widget Builders ---

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              widget.task == null
                  ? 'todo_newTask'.tr
                  : 'todo_editTask'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
           Container(
            width: 48,
            height: 48,
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.more_horiz, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // Placeholder for more options
              },
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('todo_addTag'.tr),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: InputDecoration(
             hintText: 'todo_tags'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('app_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              final tagName = tagController.text.trim();
              if (tagName.isNotEmpty && !_tags.contains(tagName)) {
                setState(() {
                  _tags.add(tagName);
                });
              }
              Navigator.pop(context);
            },
            child: Text('todo_add'.tr),
          ),
        ],
      ),
    );
  }

  void _showRemindersModal() {
     SmoothBottomSheet.show(
       context: context,
       builder: (context) => StatefulBuilder(
         builder: (context, setModalState) {
           return Container(
             padding: const EdgeInsets.all(16),
             height: 400,
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('todo_reminders'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     IconButton(
                       icon: const Icon(Icons.add),
                       onPressed: () async {
                          Navigator.pop(context); // Close modal to show picker
                          await _addReminder();
                          if (mounted) _showRemindersModal(); // Reopen
                       },
                     )
                   ],
                 ),
                 const Divider(),
                 Expanded(
                   child: ListView.builder(
                     itemCount: _reminders.length,
                     itemBuilder: (context, index) {
                       final r = _reminders[index];
                       return ListTile(
                         leading: const Icon(Icons.alarm),
                         title: Text(DateFormat.yMMMEd(Localizations.localeOf(context).toString()).add_jm().format(r)),
                         trailing: IconButton(
                           icon: const Icon(Icons.delete),
                           onPressed: () {
                             setState(() => _reminders.removeAt(index));
                             setModalState(() {});
                           },
                         ),
                       );
                     },
                   ),
                 )
               ],
             ),
           );
         }
       )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
             _buildHeader(),
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.only(bottom: 80), // Space for button
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // 基本信息组
                      _buildBasicInfoGroup(),

                      const SizedBox(height: 16),

                      // 属性组
                      _buildPropertiesGroup(),

                      const SizedBox(height: 16),

                      // 时间组
                      _buildDateGroup(),

                      const SizedBox(height: 16),

                      // 设置组
                      _buildSettingsGroup(),

                      const SizedBox(height: 32),
                   ],
                 ),
               ),
             ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: isDark ? _backgroundDark : _backgroundLight,
           border: Border(top: BorderSide(
             color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
           )),
        ),
        child: ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52), // 52px height commonly used
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26), // Full rounded
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            widget.task == null
                ? 'todo_createTask'.tr
                : 'todo_saveTask'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// 构建基本信息组（标题、描述）
  Widget _buildBasicInfoGroup() {
    return FormFieldGroup(
      children: [
        // 标题输入
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: IconTitleField(
            controller: _titleController,
            icon: _icon,
            onIconTap: () async {
              final selectedIcon = await showIconPickerDialog(
                context,
                _icon ?? Icons.assignment,
              );
              if (selectedIcon != null && mounted) {
                setState(() {
                  _icon = selectedIcon;
                });
              }
            },
            hintText: 'todo_title'.tr,
          ),
        ),
        // 描述输入
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextAreaField(
            controller: _notesController,
            hintText: 'todo_addSomeNotesHint'.tr,
            minLines: 4,
            primaryColor: _primaryColor,
          ),
        ),
      ],
    );
  }

  /// 构建属性组（标签、子任务）
  Widget _buildPropertiesGroup() {
    return FormFieldGroup(
      children: [
        // 标签管理
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'todo_tags'.tr,
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TagsField(
                tags: _tags,
                onAddTag: _showAddTagDialog,
                onRemoveTag: (tag) {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
                addButtonText: 'todo_addTag'.tr,
                primaryColor: _primaryColor,
              ),
            ],
          ),
        ),
        // 子任务管理
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'todo_subtasks'.tr,
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ListAddField<Subtask>(
                items: _subtasks,
                controller: _subtaskController,
                onAdd: _addSubtask,
                onToggle: _toggleSubtask,
                onRemove: _removeSubtask,
                getTitle: (subtask) => subtask.title,
                getIsCompleted: (subtask) => subtask.isCompleted,
                addButtonText: '${'todo_add'.tr} ${'todo_subtasks'.tr}',
                primaryColor: _primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建时间组（开始日期、截止日期）
  Widget _buildDateGroup() {
    final locale = Localizations.localeOf(context).toString();
    return FormFieldGroup(
      children: [
        DatePickerField(
          date: _startDate,
          onTap: () => _selectStartDate(context),
          formattedDate:
              _startDate != null
                  ? DateFormat.yMMMEd(locale).format(_startDate!)
                  : '',
          placeholder: DateFormat.yMMMEd(locale).format(DateTime.now()),
          icon: Icons.calendar_today_outlined,
          labelText: 'todo_startDate'.tr,
          inline: true,
        ),
        DatePickerField(
          date: _dueDate,
          onTap: () => _selectDueDate(context),
          formattedDate:
              _dueDate != null
                  ? DateFormat.yMMMEd(locale).format(_dueDate!)
                  : '',
          placeholder: DateFormat.yMMMEd(
            locale,
          ).format(DateTime.now().add(const Duration(days: 1))),
          icon: Icons.calendar_today_outlined,
          labelText: 'todo_dueDate'.tr,
          inline: true,
        ),
      ],
    );
  }

  /// 构建设置组（优先级、提醒）
  Widget _buildSettingsGroup() {
    final labels = {
      TaskPriority.high: 'todo_high'.tr,
      TaskPriority.medium: 'todo_medium'.tr,
      TaskPriority.low: 'todo_low'.tr,
    };

    return FormFieldGroup(
      children: [
        SelectField<TaskPriority>(
          value: _priority,
          onChanged: (val) {
            if (val != null) {
              setState(() => _priority = val);
            }
          },
          items:
              TaskPriority.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(labels[p] ?? ''));
              }).toList(),
          labelText: 'todo_priority'.tr,
          inline: true,
        ),
        GestureDetector(
          onTap: _showRemindersModal,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'todo_reminders'.tr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    _reminders.isNotEmpty
                        ? '${_reminders.first.month}/${_reminders.first.day} ${_reminders.first.hour}:${_reminders.first.minute.toString().padLeft(2, '0')}${_reminders.length > 1 ? ' (+${_reminders.length - 1})' : ''}'
                        : 'todo_none'.tr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          _reminders.isNotEmpty
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
