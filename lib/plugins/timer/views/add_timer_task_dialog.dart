import 'package:get/get.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_task.dart' show TimerTask;
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/core/route/route_history_manager.dart';

/// 添加/编辑计时器任务对话框
///
/// 使用 FormBuilderWrapper 进行表单管理
class AddTimerTaskDialog extends StatefulWidget {
  final List<String> groups;
  final TimerTask? initialTask;

  const AddTimerTaskDialog({super.key, required this.groups, this.initialTask});

  @override
  State<AddTimerTaskDialog> createState() => _AddTimerTaskDialogState();
}

class _AddTimerTaskDialogState extends State<AddTimerTaskDialog> {
  late final String _id;
  late final Color _selectedColor;

  // 当前表单值的缓存（用于提交前检查）
  Map<String, dynamic> _currentValues = {};

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    if (initialTask != null) {
      _id = initialTask.id;
      _selectedColor = initialTask.color;
      // 初始化当前值
      _currentValues = {
        'name': initialTask.name,
        'icon': initialTask.icon,
        'repeatCount': initialTask.repeatCount,
        'group': initialTask.group,
        'timerItems': initialTask.timerItems,
        'enableNotification': initialTask.enableNotification,
      };
    } else {
      _id = const Uuid().v4();
      _selectedColor = const Color(0xFF607AFB);
      // 初始化默认值
      _currentValues = {
        'name': '',
        'icon': Icons.psychology,
        'repeatCount': 1,
        'group': null,
        'timerItems': <TimerItem>[],
        'enableNotification': true,
      };
    }

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前编辑状态
  void _updateRouteContext() {
    final isEdit = widget.initialTask != null;
    final name = _currentValues['name'] as String? ?? '';
    final taskName = name.isNotEmpty ? name : '新计时器';

    RouteHistoryManager.updateCurrentContext(
      pageId: "/timer_edit",
      title: isEdit ? '编辑计时器 - $taskName' : '创建新计时器',
      params: {
        'mode': isEdit ? 'edit' : 'create',
        'taskId': isEdit ? _id : '',
        'taskName': taskName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1323) : const Color(0xFFF5F6F8);
    final primaryColor = const Color(0xFF607AFB);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.grey[600],
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.initialTask != null ? '编辑计时器' : '添加计时器',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FormBuilderWrapper(
            config: FormConfig(
              showSubmitButton: false,
              showResetButton: false,
              fieldSpacing: 16,
              fields: _buildFormFields(),
              onSubmit: _handleSubmit,
            ),
            contentBuilder: _buildFormContent,
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: backgroundColor,
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.4),
              ),
              child: Text(
                'app_save'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建表单内容（使用分组布局）
  Widget _buildFormContent(BuildContext context, List<Widget> fields) {
    // 提取各字段（图标字段已被移除）
    final nameField = fields[0];
    final repeatCountField = fields[1];
    final groupField = fields[2];
    final timerItemsField = fields[3];
    final notificationField = fields[4];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图标选择器
        CircleIconPickerField(
          currentIcon: _currentValues['icon'] as IconData? ?? Icons.psychology,
          currentBackgroundColor: _selectedColor,
          onValueChanged: (value) {
            setState(() {
              _currentValues['icon'] = value['icon'];
              _selectedColor = value['color'];
            });
            _updateRouteContext();
          },
        ),
        const SizedBox(height: 16),

        // 任务名称
        nameField,
        const SizedBox(height: 16),

        // 重复次数
        repeatCountField,
        const SizedBox(height: 16),

        // 分组选择
        groupField,
        const SizedBox(height: 24),

        // 计时器列表
        timerItemsField,
        const SizedBox(height: 24),

        // 通知设置
        notificationField,
      ],
    );
  }

  /// 构建表单字段配置
  List<FormFieldConfig> _buildFormFields() {
    final initialTask = widget.initialTask;

    return [
      // 任务名称
      FormFieldConfig(
        name: 'name',
        type: FormFieldType.text,
        labelText: 'timer_taskName'.tr,
        hintText: '例如: 晨间专注',
        initialValue: initialTask?.name ?? '',
        required: true,
        validationMessage: '请输入${'timer_taskName'.tr}',
        onChanged: (value) {
          setState(() => _currentValues['name'] = value);
          _updateRouteContext();
        },
      ),

      // 重复次数
      FormFieldConfig(
        name: 'repeatCount',
        type: FormFieldType.number,
        labelText: 'timer_repeatCount'.tr,
        initialValue: initialTask?.repeatCount ?? 1,
        required: true,
        onChanged: (value) => setState(() => _currentValues['repeatCount'] = value),
      ),

      // 分组选择
      FormFieldConfig(
        name: 'group',
        type: FormFieldType.text,
        labelText: 'timer_selectGroup'.tr,
        initialValue: initialTask?.group,
        extra: {
          'groups': widget.groups,
          'onGroupRenamed': _onGroupRenamed,
          'onGroupDeleted': _onGroupDeleted,
        },
        onChanged: (value) => setState(() => _currentValues['group'] = value),
      ),

      // Section 2: 子计时器列表
      FormFieldConfig(
        name: 'timerItems',
        type: FormFieldType.timerItems,
        initialValue: initialTask?.timerItems ?? [],
        onChanged: (value) => setState(() => _currentValues['timerItems'] = value),
      ),

      // Section 3: 通知开关
      FormFieldConfig(
        name: 'enableNotification',
        type: FormFieldType.switchField,
        labelText: 'timer_enableNotification'.tr,
        initialValue: initialTask?.enableNotification ?? true,
        prefixIcon: Icons.notifications,
        extra: {'inline': false},
        onChanged: (value) => setState(() => _currentValues['enableNotification'] = value),
      ),
    ];
  }

  /// 检查是否可以提交（至少需要一个子计时器）
  bool _canSubmit() {
    final timerItems = _currentValues['timerItems'] as List?;
    return timerItems != null && timerItems.isNotEmpty;
  }

  /// 提交表单
  void _submit() {
    if (_canSubmit()) {
      _handleSubmit(_currentValues);
    }
  }

  /// 处理表单提交
  void _handleSubmit(Map<String, dynamic> values) {
    final name = values['name'] as String? ?? '';
    final icon = values['icon'] as IconData? ?? Icons.psychology;
    final repeatCount = values['repeatCount'] as int? ?? 1;
    final group = values['group'] as String?;
    final timerItems = (values['timerItems'] as List?)?.cast<TimerItem>() ?? [];
    final enableNotification = values['enableNotification'] as bool? ?? true;

    final task = TimerTask.create(
      id: _id,
      name: name,
      color: _selectedColor,
      icon: icon,
      timerItems: timerItems,
      group: group,
      repeatCount: repeatCount,
      enableNotification: enableNotification,
    );

    Navigator.of(context).pop(task);
  }

  /// 分组重命名回调
  void _onGroupRenamed(String oldName, String newName) {
    if (_currentValues['group'] == oldName) {
      setState(() => _currentValues['group'] = newName);
    }
  }

  /// 分组删除回调
  void _onGroupDeleted(String groupName) {
    if (_currentValues['group'] == groupName) {
      setState(() => _currentValues['group'] = null);
    }
  }
}
