import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/todo/controllers/controllers.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/widgets/form_fields/index.dart';

/// 任务表单 - 使用 FormBuilderWrapper 重构版本
///
/// 支持创建新任务和编辑现有任务
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
  /// 表单 key（用于访问 FormBuilder 状态）
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  /// FormBuilderWrapper 状态引用
  FormBuilderWrapperState? _wrapperState;

  // 优先级标签映射
  late final Map<TaskPriority, String> _priorityLabels = {
    TaskPriority.high: 'todo_high'.tr,
    TaskPriority.medium: 'todo_medium'.tr,
    TaskPriority.low: 'todo_low'.tr,
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
  static const Color _backgroundLight = Color(0xFFF5F6F8);
  static const Color _backgroundDark = Color(0xFF0F1323);

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
    final priority = values['priority'] as TaskPriority? ?? TaskPriority.medium;
    final tags = values['tags'] as List<String>? ?? [];
    final subtasks = (values['subtasks'] as List?)?.cast<Subtask>() ?? [];
    final reminders = values['reminders'] as List<DateTime>? ?? [];

    // 确保截止日期不早于开始日期
    DateTime? adjustedDueDate = dueDate;
    if (startDate != null && adjustedDueDate != null && adjustedDueDate.isBefore(startDate)) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'todo_newTask'.tr : 'todo_editTask'.tr),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        child: FormBuilderWrapper(
          formKey: _formKey,
          onStateReady: (state) => _wrapperState = state,
          config: FormConfig(
            fieldSpacing: 0,
            showSubmitButton: false,
            showResetButton: false,
            fields: _buildFormFieldConfigs(locale),
            onSubmit: _handleSubmit,
          ),
          contentBuilder: (context, fields) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // 基本信息组
                _buildBasicInfoGroup(fields),
                const SizedBox(height: 16),
                // 属性组
                _buildPropertiesGroup(fields),
                const SizedBox(height: 16),
                // 时间组
                _buildDateGroup(fields),
                const SizedBox(height: 16),
                // 设置组
                _buildSettingsGroup(fields),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomButton(isDark),
    );
  }

  /// 构建表单字段配置
  List<FormFieldConfig> _buildFormFieldConfigs(String locale) {
    return [
      // 图标标题字段（包含图标和标题）
      FormFieldConfig(
        name: 'titleIcon',
        type: FormFieldType.iconTitle,
        initialValue: widget.task != null
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
        hintText: 'todo_addSomeNotesHint'.tr,
        extra: {'minLines': 4},
      ),

      // 标签
      FormFieldConfig(
        name: 'tags',
        type: FormFieldType.tags,
        initialValue: widget.task?.tags.toList() ?? [],
        extra: {'primaryColor': _primaryColor},
      ),

      // 子任务
      FormFieldConfig(
        name: 'subtasks',
        type: FormFieldType.listAdd,
        initialValue: widget.task?.subtasks.toList() ?? [],
        hintText: '${'todo_add'.tr} ${'todo_subtasks'.tr}',
        extra: {
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
        initialValue: widget.task?.startDate,
        hintText: DateFormat.yMMMEd(locale).format(DateTime.now()),
        labelText: 'todo_startDate'.tr,
        extra: {
          'inline': true,
          'format': 'yMMMEd',
        },
      ),

      // 截止日期
      FormFieldConfig(
        name: 'dueDate',
        type: FormFieldType.date,
        initialValue: widget.task?.dueDate,
        hintText: DateFormat.yMMMEd(locale).format(
          DateTime.now().add(const Duration(days: 1)),
        ),
        labelText: 'todo_dueDate'.tr,
        extra: {
          'inline': true,
          'format': 'yMMMEd',
        },
      ),

      // 优先级
      FormFieldConfig(
        name: 'priority',
        type: FormFieldType.select,
        initialValue: widget.task?.priority ?? TaskPriority.medium,
        labelText: 'todo_priority'.tr,
        items: TaskPriority.values.map((p) {
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

  /// 构建底部按钮
  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _backgroundDark : _backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: () async {
          // 使用 FormBuilderWrapperState 保存并验证所有字段
          if (_wrapperState != null) {
            final isValid = _wrapperState!.saveAndValidate();
            if (isValid) {
              await _handleSubmit(_wrapperState!.currentValues);
            }
          } else {
            final fbState = _formKey.currentState;
            if (fbState != null && fbState.saveAndValidate()) {
              await _handleSubmit(fbState.value);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.task == null ? 'todo_createTask'.tr : 'todo_saveTask'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 构建基本信息组
  Widget _buildBasicInfoGroup(List<Widget> fields) {
    return FormFieldGroup(
      children: [
        // 图标标题字段
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[0], // titleIcon field
        ),
        // 描述输入
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[1], // description field
        ),
      ],
    );
  }

  /// 构建属性组（标签、子任务）
  Widget _buildPropertiesGroup(List<Widget> fields) {
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              fields[2], // tags field
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              fields[3], // subtasks field
            ],
          ),
        ),
      ],
    );
  }

  /// 构建时间组（开始日期、截止日期）
  Widget _buildDateGroup(List<Widget> fields) {
    return FormFieldGroup(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[4], // startDate field
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[5], // dueDate field
        ),
      ],
    );
  }

  /// 构建设置组（优先级、提醒）
  Widget _buildSettingsGroup(List<Widget> fields) {
    return FormFieldGroup(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[6], // priority field
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: fields[7], // reminders field
        ),
      ],
    );
  }
}
