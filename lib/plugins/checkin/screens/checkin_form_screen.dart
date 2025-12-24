import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/widgets/form_fields/index.dart';

/// 打卡项目表单屏幕
///
/// 使用 FormBuilderWrapper 进行声明式表单构建
class CheckinFormScreen extends StatefulWidget {
  /// 初始打卡项目（编辑模式）
  final CheckinItem? initialItem;

  const CheckinFormScreen({super.key, this.initialItem});

  @override
  State<CheckinFormScreen> createState() => _CheckinFormScreenState();
}

class _CheckinFormScreenState extends State<CheckinFormScreen> {
  /// 表单 key
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  /// 现有分组集合
  Set<String> _existingGroups = <String>{};

  /// 现有名称集合
  Set<String> _existingNames = <String>{};

  /// 当前提醒类型（用于条件显示字段）
  ReminderType? _currentReminderType;

  @override
  void initState() {
    super.initState();
    _currentReminderType = widget.initialItem?.reminderSettings?.type;
    _loadExistingData();

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文
  void _updateRouteContext() {
    final isEdit = widget.initialItem != null;
    final itemName = widget.initialItem?.name ?? '';

    if (isEdit) {
      RouteHistoryManager.updateCurrentContext(
        pageId: "/checkin_form_edit",
        title: '编辑打卡项目 - $itemName',
        params: {'itemName': itemName},
      );
    } else {
      RouteHistoryManager.updateCurrentContext(
        pageId: "/checkin_form_new",
        title: '新建打卡项目',
        params: {},
      );
    }
  }

  /// 加载现有分组和名称
  void _loadExistingData() {
    final items = CheckinPlugin.shared.checkinItems;
    if (items.isNotEmpty) {
      _existingGroups = items.map((item) => item.group).whereType<String>().toSet();
      if (_existingGroups.isEmpty) {
        _existingGroups.add('默认分组');
      }

      _existingNames = items
          .where((item) => item.id != widget.initialItem?.id)
          .map((item) => item.name)
          .toSet();
    } else {
      _existingGroups = {'默认分组'};
      _existingNames = {};
    }
  }

  /// 验证名称是否重复
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'checkin_nameRequiredError'.tr;
    }
    if (_existingNames.contains(value.trim())) {
      return 'checkin_nameExistsError'.tr;
    }
    return null;
  }

  /// 提交表单
  void _handleSubmit(Map<String, dynamic> values) {
    // 图标颜色数据
    final iconColorData = values['iconColor'] as Map<String, dynamic>;
    final icon = iconColorData['icon'] as IconData;
    final color = iconColorData['color'] as Color;

    // 提醒设置
    ReminderSettings? reminderSettings;
    final reminderType = values['reminderType'] as ReminderType?;
    if (reminderType != null) {
      switch (reminderType) {
        case ReminderType.weekly:
          final weekdays = values['weekdays'] as List<int>? ?? [];
          reminderSettings = ReminderSettings(
            type: reminderType,
            weekdays: weekdays,
            timeOfDay: values['reminderTime'] as TimeOfDay? ?? TimeOfDay.now(),
          );
          break;
        case ReminderType.monthly:
          reminderSettings = ReminderSettings(
            type: reminderType,
            dayOfMonth: values['monthDay'] as int?,
            timeOfDay: values['reminderTime'] as TimeOfDay? ?? TimeOfDay.now(),
          );
          break;
        case ReminderType.specific:
          reminderSettings = ReminderSettings(
            type: reminderType,
            specificDate: values['specificDate'] as DateTime?,
            timeOfDay: values['reminderTime'] as TimeOfDay? ?? TimeOfDay.now(),
          );
          break;
      }
    }

    // 分组处理
    final groupValue = values['group'] as String?;
    final String? trimmedGroup = groupValue?.trim();
    final group = (trimmedGroup == null || trimmedGroup.isEmpty) ? null : trimmedGroup;

    // 构建打卡项目
    final item = CheckinItem(
      id: widget.initialItem?.id,
      name: (values['name'] as String).trim(),
      icon: icon,
      color: color,
      group: group,
      reminderSettings: reminderSettings,
      checkInRecords: widget.initialItem?.checkInRecords ?? {},
    );

    Navigator.of(context).pop(item);
  }

  /// 提醒类型变化回调
  void _onReminderTypeChanged(dynamic value) {
    final type = value is ReminderType ? value : null;
    setState(() {
      _currentReminderType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialItem == null
              ? 'checkin_addCheckinItem'.tr
              : 'checkin_editCheckinItemTitle'.tr,
        ),
      ),
      body: FormBuilderWrapper(
        formKey: _formKey,
        config: FormConfig(
          submitButtonText: 'checkin_save'.tr,
          showSubmitButton: false, // 使用自定义按钮
          showResetButton: false,
          fieldSpacing: 16,
          onValidationFailed: (errors) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errors.values.join(', ')),
              ),
            );
          },
          onSubmit: _handleSubmit,
          fields: [
            // 图标和颜色选择器
            FormFieldConfig(
              name: 'iconColor',
              type: FormFieldType.circleIconPicker,
              initialValue: {
                'icon': widget.initialItem?.icon ?? Icons.check_circle,
                'color': widget.initialItem?.color ?? Colors.blue,
              },
            ),

            // 名称输入框
            FormFieldConfig(
              name: 'name',
              type: FormFieldType.text,
              labelText: 'checkin_nameLabel'.tr,
              hintText: 'checkin_nameHint'.tr,
              initialValue: widget.initialItem?.name ?? '',
              required: true,
              validationMessage: 'checkin_nameRequiredError'.tr,
            ),

            // 分组输入框
            FormFieldConfig(
              name: 'group',
              type: FormFieldType.text,
              labelText: 'checkin_groupLabel'.tr,
              hintText: 'checkin_groupHint'.tr,
              initialValue: widget.initialItem?.group ?? '',
            ),

            // 提醒类型选择器
            FormFieldConfig(
              name: 'reminderType',
              type: FormFieldType.select,
              labelText: 'checkin_reminderTypeLabel'.tr,
              initialValue: widget.initialItem?.reminderSettings?.type,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('checkin_noReminder'.tr),
                ),
                ...ReminderType.values.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(switch (type) {
                      ReminderType.weekly => 'checkin_weeklyReminder'.tr,
                      ReminderType.monthly => 'checkin_monthlyReminder'.tr,
                      ReminderType.specific => 'checkin_specificDateReminder'.tr,
                    }),
                  ),
                ),
              ],
              onChanged: _onReminderTypeChanged,
            ),

            // 月份日期选择器（仅当选择每月提醒时显示）
            FormFieldConfig(
              name: 'monthDay',
              type: FormFieldType.select,
              labelText: 'checkin_monthlyReminderDayLabel'.tr,
              initialValue: widget.initialItem?.reminderSettings?.dayOfMonth,
              visible: (values) => values['reminderType'] == ReminderType.monthly,
              items: List.generate(31, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}${'checkin_daySuffix'.tr}'),
                );
              }),
            ),

            // 特定日期选择器（仅当选择特定日期提醒时显示）
            FormFieldConfig(
              name: 'specificDate',
              type: FormFieldType.date,
              labelText: 'checkin_selectDate'.tr,
              initialValue: widget.initialItem?.reminderSettings?.specificDate,
              visible: (values) => values['reminderType'] == ReminderType.specific,
              extra: {
                'firstDate': DateTime.now(),
                'lastDate': DateTime.now().add(const Duration(days: 365 * 2)),
              },
            ),

            // 提醒时间选择器（有提醒类型时显示）
            FormFieldConfig(
              name: 'reminderTime',
              type: FormFieldType.time,
              labelText: 'checkin_selectTime'.tr,
              initialValue: widget.initialItem?.reminderSettings?.timeOfDay ?? TimeOfDay.now(),
              visible: (values) => values['reminderType'] != null,
            ),
          ],
        ),
        contentBuilder: (context, fields) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标准字段
              for (final field in fields) ...[
                field,
                const SizedBox(height: 16),
              ],

              // 星期选择器（条件显示）
              if (_currentReminderType == ReminderType.weekly) ...[
                _buildWeekdaySelector(),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
        buttonBuilder: (context, onSubmit, onReset) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    // 手动验证名称字段
                    final nameValue = _formKey.currentState?.fields['name']?.value as String?;
                    final nameError = _validateName(nameValue);
                    if (nameError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(nameError)),
                      );
                      return;
                    }
                    onSubmit();
                  },
                  child: Text('checkin_save'.tr),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建星期选择器
  Widget _buildWeekdaySelector() {
    final weekdays = [
      'checkin_sunday'.tr,
      'checkin_monday'.tr,
      'checkin_tuesday'.tr,
      'checkin_wednesday'.tr,
      'checkin_thursday'.tr,
      'checkin_friday'.tr,
      'checkin_saturday'.tr,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: FormBuilderField<List<int>>(
        name: 'weekdays',
        initialValue: widget.initialItem?.reminderSettings?.weekdays ?? <int>[],
        builder: (fieldState) {
          final selectedWeekdays = fieldState.value ?? <int>[];
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final isSelected = selectedWeekdays.contains(index);
              return InkWell(
                onTap: () {
                  final newWeekdays = List<int>.from(selectedWeekdays);
                  if (isSelected) {
                    newWeekdays.remove(index);
                  } else {
                    newWeekdays.add(index);
                  }
                  fieldState.didChange(newWeekdays);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    weekdays[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
