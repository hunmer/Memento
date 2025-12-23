import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/utils/date_time_utils.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/form_fields/index.dart';

class CheckinFormScreen extends StatefulWidget {
  final CheckinItem? initialItem;

  const CheckinFormScreen({super.key, this.initialItem});

  @override
  State<CheckinFormScreen> createState() => _CheckinFormScreenState();
}

class _CheckinFormScreenState extends State<CheckinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late IconData _icon;
  late Color _color;
  ReminderSettings? _reminderSettings;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  Set<String> _existingGroups = <String>{};
  Set<String> _existingNames = <String>{};

  @override
  void initState() {
    super.initState();
    // 使用初始项目的值或默认值
    _icon = widget.initialItem?.icon ?? Icons.check_circle;
    _color = widget.initialItem?.color ?? Colors.blue;
    _reminderSettings = widget.initialItem?.reminderSettings;

    // 设置控制器的文本
    _nameController.text = widget.initialItem?.name ?? '';
    _groupController.text = widget.initialItem?.group ?? '';

    // 加载现有分组和名称
    _loadExistingData();

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前编辑的模式和项目
  void _updateRouteContext() {
    final isEdit = widget.initialItem != null;
    final itemName = _nameController.text.trim();

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

  // 加载现有分组和名称
  void _loadExistingData() {
    final items = CheckinPlugin.shared.checkinItems;
    if (items.isNotEmpty) {
      // 加载分组
      _existingGroups = items.map((item) => item.group).toSet();
      if (_existingGroups.isEmpty) {
        _existingGroups.add('默认分组');
      }

      // 加载名称，排除当前编辑项
      _existingNames = items
          .where((item) => item.id != widget.initialItem?.id)
          .map((item) => item.name)
          .toSet();
    } else {
      _existingGroups = {'默认分组'};
      _existingNames = {};
    }
  }

  // 显示分组选择对话框

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
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
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final name = _nameController.text.trim();
                final group = _groupController.text.trim().isEmpty
                    ? null
                    : _groupController.text.trim();
                final item = CheckinItem(
                  id: widget.initialItem?.id,
                  name: name,
                  icon: _icon,
                  color: _color,
                  group: group,
                  reminderSettings: _reminderSettings,
                  checkInRecords:
                      widget.initialItem?.checkInRecords ?? {}, // 保留打卡记录
                );
                Navigator.of(context).pop(item);
              }
            },
            child: Text('checkin_save'.tr),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 圆形图标和颜色选择控件
            CircleIconPicker(
              currentIcon: _icon,
              backgroundColor: _color,
              onIconSelected: (icon) => setState(() => _icon = icon),
              onColorSelected: (color) => setState(() => _color = color),
            ),
            const SizedBox(height: 24),
            // 名称输入框
            TextInputField(
              controller: _nameController,
              labelText: 'checkin_nameLabel'.tr,
              hintText: 'checkin_nameHint'.tr,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'checkin_nameRequiredError'.tr;
                }
                if (_existingNames.contains(value.trim())) {
                  return 'checkin_nameExistsError'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 分组输入框
            TextInputField(
              controller: _groupController,
              labelText: 'checkin_groupLabel'.tr,
              hintText: 'checkin_groupHint'.tr,
            ),
            const SizedBox(height: 24),
            // 提醒设置
            const SizedBox(height: 8),
            _buildReminderTypeSelector(),
            const SizedBox(height: 16),
            if (_reminderSettings?.type == ReminderType.weekly)
              _buildWeekdaySelector()
            else if (_reminderSettings?.type == ReminderType.monthly)
              _buildMonthDaySelector()
            else if (_reminderSettings?.type == ReminderType.specific)
              _buildSpecificDateSelector(),
            if (_reminderSettings != null) ...[
              const SizedBox(height: 16),
              _buildTimeSelector(),
            ],
          ],
        ),
      ),
    );
  }

  // 提醒类型选择器
  Widget _buildReminderTypeSelector() {
    return SelectField<ReminderType?>(
      value: _reminderSettings?.type,
      labelText: 'checkin_reminderTypeLabel'.tr,
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
      onChanged: (value) {
        setState(() {
          if (value == null) {
            _reminderSettings = null;
          } else {
            _reminderSettings = ReminderSettings(
              type: value,
              weekdays: const [],
              timeOfDay: TimeOfDay.now(),
            );
          }
        });
      },
    );
  }

  // 星期选择器
  Widget _buildWeekdaySelector() {
    final theme = Theme.of(context);
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
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (index) {
          final isSelected = _reminderSettings?.weekdays.contains(index) ?? false;
          return InkWell(
            onTap: () {
              setState(() {
                final List<int> newWeekdays = List.from(
                  _reminderSettings?.weekdays ?? [],
                );
                if (isSelected) {
                  newWeekdays.remove(index);
                } else {
                  newWeekdays.add(index);
                }
                _reminderSettings = ReminderSettings(
                  type: ReminderType.weekly,
                  weekdays: newWeekdays,
                  timeOfDay: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
                );
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 月份日期选择器
  Widget _buildMonthDaySelector() {
    return SelectField<int?>(
      value: _reminderSettings?.dayOfMonth,
      labelText: 'checkin_monthlyReminderDayLabel'.tr,
      items: List.generate(31, (index) {
        return DropdownMenuItem(
          value: index + 1,
          child: Text(
            '${index + 1}${'checkin_daySuffix'.tr}',
          ),
        );
      }),
      onChanged: (value) {
        setState(() {
          _reminderSettings = ReminderSettings(
            type: ReminderType.monthly,
            dayOfMonth: value,
            timeOfDay: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
          );
        });
      },
    );
  }

  // 特定日期选择器
  Widget _buildSpecificDateSelector() {
    return DatePickerField(
      date: _reminderSettings?.specificDate,
      formattedDate: _reminderSettings?.specificDate != null
          ? DateTimeUtils.formatDate(_reminderSettings!.specificDate!)
          : '',
      placeholder: 'checkin_selectDate'.tr,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _reminderSettings?.specificDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          setState(() {
            _reminderSettings = ReminderSettings(
              type: ReminderType.specific,
              specificDate: date,
              timeOfDay: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
            );
          });
        }
      },
    );
  }

  // 时间选择器
  Widget _buildTimeSelector() {
    return TimePickerField(
      label: 'checkin_selectTime'.tr,
      time: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
      onTimeChanged: (time) {
        setState(() {
          _reminderSettings = ReminderSettings(
            type: _reminderSettings!.type,
            weekdays: _reminderSettings!.weekdays,
            dayOfMonth: _reminderSettings!.dayOfMonth,
            specificDate: _reminderSettings!.specificDate,
            timeOfDay: time,
          );
        });
      },
    );
  }
}
