import 'package:get/get.dart';
import 'package:Memento/widgets/icon_picker_dialog.dart';
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

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionContainer(
      label: 'todo_notes'.tr,
      child: TextAreaField(
        controller: _notesController,
        hintText: 'todo_addSomeNotesHint'.tr,
        minLines: 4,
        primaryColor: _primaryColor,
      ),
    );
  }

  Widget _buildTagsSection() {
    return _buildSectionContainer(
      label: 'todo_tags'.tr,
      child: TagsField(
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
    );
  }

  Widget _buildSubtasksSection() {
    return _buildSectionContainer(
      label: 'todo_subtasks'.tr,
      child: ListAddField<Subtask>(
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
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildInputBox(
              label: 'todo_startDate'.tr,
              icon: Icons.calendar_today_outlined,
              value: _startDate != null ? DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(_startDate!) : '',
              placeholder: DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(DateTime.now()),
              onTap: () => _selectStartDate(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInputBox(
              label: 'todo_dueDate'.tr,
              icon: Icons.calendar_today_outlined,
              value: _dueDate != null ? DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(_dueDate!) : '',
              placeholder: DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(DateTime.now().add(const Duration(days: 1))),
              onTap: () => _selectDueDate(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAndReminderSection() {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildPriorityDropdown(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildReminderDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    final labels = {
      TaskPriority.high: 'todo_high'.tr,
      TaskPriority.medium: 'todo_medium'.tr,
      TaskPriority.low: 'todo_low'.tr,
    };

    return _buildSectionContainer(
      label: 'todo_priority'.tr.replaceAll(':', ''),
      child: SelectField<TaskPriority>(
        value: _priority,
        onChanged: (val) {
          if (val != null) {
            setState(() => _priority = val);
          }
        },
        items: TaskPriority.values.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(labels[p] ?? ''),
          );
        }).toList(),
        icon: Icons.flag_outlined,
        primaryColor: _primaryColor,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildReminderDropdown() {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     String text = 'todo_none'.tr;
     if (_reminders.isNotEmpty) {
       final r = _reminders.first;
       text = '${r.month}/${r.day} ${r.hour}:${r.minute.toString().padLeft(2,'0')}';
       if (_reminders.length > 1) text += ' (+${_reminders.length - 1})';
     }

     return _buildSectionContainer(
      label: 'todo_reminders'.tr,
      child: GestureDetector(
        onTap: _showRemindersModal,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
               color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_outlined, color: isDark ? Colors.grey[500] : Colors.grey[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                   style: TextStyle(
                     fontSize: 16,
                     color: isDark ? Colors.white : Colors.grey[900],
                   ),
                ),
              ),
              Icon(Icons.expand_more, color: isDark ? Colors.grey[500] : Colors.grey[400]),
            ],
          ),
        ),
      ),
      padding: EdgeInsets.zero
    );
  }

  Widget _buildInputBox({
    required String label,
    required IconData icon,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DatePickerField(
          date: value.isNotEmpty ? DateTime.now() : null,
          onTap: onTap,
          formattedDate: value,
          placeholder: placeholder,
          icon: icon,
        ),
      ],
    );
  }

  Widget _buildSectionContainer({required String label, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16)}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4), // Align label with input padding if needed, or keep consistent 16
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child,
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
      backgroundColor: isDark ? _backgroundDark : _backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
             _buildHeader(),
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.only(bottom: 80), // Space for button
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const SizedBox(height: 8),
                     _buildTitleSection(),
                     const SizedBox(height: 24),
                     _buildNotesSection(),
                     const SizedBox(height: 16),
                     _buildTagsSection(),
                     const SizedBox(height: 16),
                     _buildSubtasksSection(),
                     const SizedBox(height: 16),
                     _buildDateSection(),
                     const SizedBox(height: 16),
                     _buildPriorityAndReminderSection(),
                     const SizedBox(height: 32),
                   ],
                 ),
               ),
             ),
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
}
