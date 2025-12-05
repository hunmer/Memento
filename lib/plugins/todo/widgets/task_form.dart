import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:Memento/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../controllers/controllers.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TodoLocalizations.of(context).pleaseEnterTitle),
        ),
      );
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
                  ? TodoLocalizations.of(context).newTask
                  : TodoLocalizations.of(context).editTask,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
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
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon ?? Icons.assignment,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: TodoLocalizations.of(context).title,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionContainer(
      label: TodoLocalizations.of(context).notes,
      child: TextField(
        controller: _notesController,
        maxLines: null,
        minLines: 4,
        style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
        decoration: InputDecoration(
          hintText: 'Add some notes...',
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
               color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(
               color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            ),
          ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: const BorderSide(
               color: _primaryColor,
               width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionContainer(
      label: TodoLocalizations.of(context).tags,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
           border: Border.all(
             color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
           ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._tags.map((tag) => _buildTagChip(tag)),
            InkWell(
              onTap: _showAddTagDialog,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, color: _primaryColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      TodoLocalizations.of(context).addTag,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF607AFB).withOpacity(0.2) : const Color(0xFFEFF6FF), // Blue-50 equivalent
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF), // Blue-300 : Blue-800
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _tags.remove(tag);
              });
            },
            child: Icon(
              Icons.close,
              size: 14,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
     return _buildSectionContainer(
      label: TodoLocalizations.of(context).subtasks,
      child: Container(
        decoration: BoxDecoration(
           color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            if (_subtasks.isNotEmpty)
              ..._subtasks.asMap().entries.map((entry) {
                 final index = entry.key;
                 final subtask = entry.value;
                 return Container(
                   decoration: BoxDecoration(
                     border: Border(bottom: BorderSide(
                       color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                     )),
                   ),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   child: Row(
                     children: [
                       SizedBox(
                         width: 20,
                         height: 20,
                         child: Checkbox(
                           value: subtask.isCompleted,
                           onChanged: (_) => _toggleSubtask(index),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                           activeColor: _primaryColor,
                           side: BorderSide(
                             color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[400]!,
                             width: 2,
                           ),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           subtask.title,
                           style: TextStyle(
                             decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                             fontSize: 16,
                             color: isDark ? Colors.white : Colors.grey[900],
                           ),
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close, size: 18),
                         onPressed: () => _removeSubtask(index),
                         color: isDark ? Colors.grey[400] : Colors.grey[500],
                       )
                     ],
                   ),
                 );
              }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: _addSubtask,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                         const Icon(Icons.add_circle_outline, color: _primaryColor, size: 20),
                         const SizedBox(width: 8),
                         Text(
                            '${TodoLocalizations.of(context).add} ${TodoLocalizations.of(context).subtasks}',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
                      decoration: InputDecoration(
                        hintText: '', // Placeholder is covered by the button text effectively or we can add one
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              label: TodoLocalizations.of(context).startDate,
              icon: Icons.calendar_today_outlined,
              value: _startDate != null ? DateFormat.yMMMEd().format(_startDate!) : '',
              placeholder: DateFormat.yMMMEd().format(DateTime.now()),
              onTap: () => _selectStartDate(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInputBox(
              label: TodoLocalizations.of(context).dueDate,
              icon: Icons.calendar_today_outlined,
              value: _dueDate != null ? DateFormat.yMMMEd().format(_dueDate!) : '',
              placeholder: DateFormat.yMMMEd().format(DateTime.now().add(const Duration(days: 1))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = {
      TaskPriority.high: TodoLocalizations.of(context).high,
      TaskPriority.medium: TodoLocalizations.of(context).medium,
      TaskPriority.low: TodoLocalizations.of(context).low,
    };

    return _buildSectionContainer(
      label: TodoLocalizations.of(context).priority.replaceAll(':', ''), // Remove colon if present in loc
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
            Icon(Icons.flag_outlined, color: isDark ? Colors.grey[500] : Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaskPriority>(
                  value: _priority,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: Icon(Icons.expand_more, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                    fontSize: 16,
                  ),
                  items: TaskPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(labels[p] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _priority = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      padding: EdgeInsets.zero
    );
  }

  Widget _buildReminderDropdown() {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     String text = 'None';
     if (_reminders.isNotEmpty) {
       final r = _reminders.first;
       text = '${r.month}/${r.day} ${r.hour}:${r.minute.toString().padLeft(2,'0')}';
       if (_reminders.length > 1) text += ' (+${_reminders.length - 1})';
     }

     return _buildSectionContainer(
      label: TodoLocalizations.of(context).reminders,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(left: 10, right: 12), // Adjust padding for icon alignment
             decoration: BoxDecoration(
               color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                 color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.isEmpty ? placeholder : value,
                    style: TextStyle(
                       color: value.isEmpty 
                          ? (isDark ? Colors.grey[500] : Colors.grey[400]) 
                          : (isDark ? Colors.white : Colors.grey[900]),
                       fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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
        title: Text(TodoLocalizations.of(context).addTag),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: InputDecoration(
             hintText: TodoLocalizations.of(context).tags,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
            },
            child: Text(TodoLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  void _showRemindersModal() {
     showModalBottomSheet(
       context: context, 
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
       shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
       ),
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
                     Text(TodoLocalizations.of(context).reminders, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                         title: Text(DateFormat.yMMMEd().add_jm().format(r)),
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
                ? TodoLocalizations.of(context).createTask
                : TodoLocalizations.of(context).saveTask, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
