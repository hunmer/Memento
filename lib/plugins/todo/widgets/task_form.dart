import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/todo/controllers/controllers.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';

/// 任务表单 - 使用 FormBuilderWrapper 重构版本
///
/// 支持创建新任务和编辑现有任务
class TaskForm extends StatefulWidget {
  final Task? task; // If null, create new task
  final TaskController taskController;
  final ReminderController reminderController;
  final TaskPriority? initialPriority; // 预设优先级（仅用于创建新任务）
  final DateTime? initialStartDate; // 预设开始日期（仅用于创建新任务）

  const TaskForm({
    super.key,
    this.task,
    required this.taskController,
    required this.reminderController,
    this.initialPriority,
    this.initialStartDate,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  /// FormBuilderWrapper key
  final GlobalKey<FormBuilderWrapperState> _formKey = GlobalKey<FormBuilderWrapperState>();

  /// FormBuilderWrapper 状态引用
  FormBuilderWrapperState? _formWrapperState;

  // 优先级标签映射
  late final Map<TaskPriority, String> _priorityLabels = {
    TaskPriority.q1: 'todo_q1'.tr,
    TaskPriority.q2: 'todo_q2'.tr,
    TaskPriority.q3: 'todo_q3'.tr,
    TaskPriority.q4: 'todo_q4'.tr,
  };

  @override
  void initState() {
    super.initState();
    _updateRouteContext();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 自定义颜色
  static const Color _primaryColor = Color(0xFF607AFB);

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

  /// 保存任务
  Future<void> _handleSubmit(Map<String, dynamic> values) async {
    // 从 iconTitle 字段获取标题和图标
    final titleIconData = values['titleIcon'] as Map?;
    final title = titleIconData?['title'] as String? ?? '';
    final icon = titleIconData?['icon'] as IconData?;

    if (title.isEmpty) {
      Toast.error('todo_pleaseEnterTitle'.tr);
      return;
    }

    // 收集表单数据
    final description = values['description'] as String?;
    final startDate = values['startDate'] as DateTime?;
    final dueDate = values['dueDate'] as DateTime?;
    final priority = values['priority'] as TaskPriority? ?? TaskPriority.q2;
    final tags = values['tags'] as List<String>? ?? [];
    final subtasks = (values['subtasks'] as List?)?.cast<Subtask>() ?? [];
    final reminders = values['reminders'] as List<DateTime>? ?? [];

    // 确保截止日期不早于开始日期
    DateTime? adjustedDueDate = dueDate;
    if (startDate != null &&
        adjustedDueDate != null &&
        adjustedDueDate.isBefore(startDate)) {
      adjustedDueDate = null;
    }

    if (widget.task == null) {
      // 创建新任务
      await widget.taskController.createTask(
        title: title,
        description: description?.isEmpty ?? true ? null : description,
        startDate: startDate,
        dueDate: adjustedDueDate,
        priority: priority,
        tags: tags,
        subtasks: subtasks,
        reminders: reminders,
        icon: icon ?? Icons.assignment,
      );
    } else {
      // 更新现有任务
      final updatedTask = widget.task!.copyWith(
        title: title,
        description: description?.isEmpty ?? true ? null : description,
        startDate: startDate,
        dueDate: adjustedDueDate,
        priority: priority,
        tags: tags,
        subtasks: subtasks,
        reminders: reminders,
        icon: icon ?? widget.task!.icon,
      );
      await widget.taskController.updateTask(updatedTask);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// 确认删除任务
  Future<void> _confirmDelete() async {
    if (widget.task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('todo_deleteTaskTitle'.tr),
            content: Text('todo_deleteTaskMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'app_delete'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.taskController.deleteTask(widget.task!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null ? 'todo_newTask'.tr : 'todo_editTask'.tr,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'app_delete'.tr,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _formWrapperState?.submitForm(),
            tooltip: 'app_save'.tr,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: FormBuilderWrapper(
                key: _formKey,
                onStateReady: (state) => _formWrapperState = state,
                config: FormConfig(
                  fieldSpacing: 16,
                  showSubmitButton: false,
                  showResetButton: false,
                  fields: _buildFormFieldConfigs(locale),
                  onSubmit: _handleSubmit,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建表单字段配置
  List<FormFieldConfig> _buildFormFieldConfigs(String locale) {
    return [
      // 图标标题字段（包含图标和标题）
      FormFieldConfig(
        name: 'titleIcon',
        type: FormFieldType.iconTitle,
        initialValue:
            widget.task != null
                ? {'title': widget.task!.title, 'icon': widget.task!.icon}
                : {'title': '', 'icon': Icons.assignment},
        required: true,
        validationMessage: 'todo_pleaseEnterTitle'.tr,
        hintText: 'todo_title'.tr,
      ),

      // 描述
      FormFieldConfig(
        name: 'description',
        type: FormFieldType.textArea,
        initialValue: widget.task?.description ?? '',
        labelText: 'todo_description'.tr,
        hintText: 'todo_addSomeNotesHint'.tr,
        extra: {'minLines': 4},
      ),

      // 标签
      FormFieldConfig(
        name: 'tags',
        type: FormFieldType.tags,
        initialValue: widget.task?.tags.toList() ?? [],
        labelText: 'todo_tags'.tr,
        extra: {'primaryColor': _primaryColor},
      ),

      // 子任务
      FormFieldConfig(
        name: 'subtasks',
        type: FormFieldType.listAdd,
        initialValue: widget.task?.subtasks.toList() ?? [],
        labelText: 'todo_subtasks'.tr,
        hintText: '${'todo_add'.tr} ${'todo_subtasks'.tr}',
        extra: {
          'initialItems': widget.task?.subtasks.toList() ?? [],
          'primaryColor': _primaryColor,
          'getTitle': (Subtask s) => s.title,
          'getIsCompleted': (Subtask s) => s.isCompleted,
          'onToggle': (int index, Subtask item) {
            // 切换子任务状态需要在提交时处理
            // 这里暂时不做实时处理
          },
          'onCreate':
              (String text) => Subtask(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: text,
                isCompleted: false,
              ),
        },
      ),

      // 开始日期
      FormFieldConfig(
        name: 'startDate',
        type: FormFieldType.date,
        initialValue: widget.task?.startDate ?? widget.initialStartDate,
        hintText: DateFormat.yMMMEd(locale).format(DateTime.now()),
        labelText: 'todo_startDate'.tr,
        extra: {'inline': true, 'format': 'yMMMEd'},
      ),

      // 截止日期
      FormFieldConfig(
        name: 'dueDate',
        type: FormFieldType.date,
        initialValue: widget.task?.dueDate,
        hintText: DateFormat.yMMMEd(locale).format(DateTime.now().add(const Duration(days: 1))),
        labelText: 'todo_dueDate'.tr,
        extra: {'inline': true, 'format': 'yMMMEd'},
      ),

      // 优先级
      FormFieldConfig(
        name: 'priority',
        type: FormFieldType.select,
        initialValue: widget.task?.priority ?? widget.initialPriority ?? TaskPriority.q2,
        labelText: 'todo_priority'.tr,
        items:
            TaskPriority.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(_priorityLabels[p] ?? ''),
              );
            }).toList(),
      ),

      // 提醒
      FormFieldConfig(
        name: 'reminders',
        type: FormFieldType.reminders,
        initialValue: widget.task?.reminders.toList() ?? [],
        labelText: 'todo_reminders'.tr,
        hintText: 'todo_none'.tr,
        extra: {'primaryColor': _primaryColor},
      ),
    ];
  }
}
