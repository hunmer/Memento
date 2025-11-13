import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/l10n/checkin_localizations.dart';
import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../../../utils/date_time_utils.dart';
import '../../../widgets/circle_icon_picker.dart';

class CheckinFormScreen extends StatefulWidget {
  final CheckinItem? initialItem;

  const CheckinFormScreen({super.key, this.initialItem});

  @override
  State<CheckinFormScreen> createState() => _CheckinFormScreenState();
}

class _CheckinFormScreenState extends State<CheckinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late IconData _icon;
  late String? _group;
  late Color _color;
  ReminderSettings? _reminderSettings;
  final TextEditingController _groupController = TextEditingController();
  Set<String> _existingGroups = <String>{};
  Set<String> _existingNames = <String>{};

  @override
  void initState() {
    super.initState();
    // 使用初始项目的值或默认值
    _name = widget.initialItem?.name ?? '';
    _icon = widget.initialItem?.icon ?? Icons.check_circle;
    _group = widget.initialItem?.group;
    _color = widget.initialItem?.color ?? Colors.blue;
    _reminderSettings = widget.initialItem?.reminderSettings;

    // 设置分组控制器的文本
    _groupController.text = _group ?? '';

    // 加载现有分组和名称
    _loadExistingData();
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
      _existingNames =
          items
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
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialItem == null
              ? CheckinLocalizations.of(context).addCheckinItem
              : CheckinLocalizations.of(context).editCheckinItemTitle,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final item = CheckinItem(
                  id: widget.initialItem?.id,
                  name: _name,
                  icon: _icon,
                  color: _color,
                  group: _group,
                  reminderSettings: _reminderSettings,
                  checkInRecords:
                      widget.initialItem?.checkInRecords ?? {}, // 保留打卡记录
                );
                Navigator.of(context).pop(item);
              }
            },
            child: Text(CheckinLocalizations.of(context).save),
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
            TextFormField(
              decoration: InputDecoration(
                labelText: CheckinLocalizations.of(context).nameLabel,
                hintText: CheckinLocalizations.of(context).nameHint,
              ),
              initialValue: _name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return CheckinLocalizations.of(context).nameRequiredError;
                }
                if (_existingNames.contains(value.trim())) {
                  return CheckinLocalizations.of(context).nameExistsError;
                }
                return null;
              },
              onSaved: (value) => _name = value!.trim(),
            ),
            const SizedBox(height: 16),
            // 分组输入框
            TextFormField(
              decoration: InputDecoration(
                labelText: CheckinLocalizations.of(context).groupLabel,
                hintText: CheckinLocalizations.of(context).groupHint,
              ),
              initialValue: _group,
              onSaved:
                  (value) =>
                      _group = value?.trim().isEmpty == true ? null : value,
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
    return DropdownButtonFormField<ReminderType>(
      decoration: InputDecoration(
        labelText: CheckinLocalizations.of(context).reminderTypeLabel,
        border: const OutlineInputBorder(),
      ),
      value: _reminderSettings?.type,
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(CheckinLocalizations.of(context).noReminder),
        ),
        ...ReminderType.values.map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(switch (type) {
              ReminderType.weekly =>
                CheckinLocalizations.of(context).weeklyReminder,
              ReminderType.monthly =>
                CheckinLocalizations.of(context).monthlyReminder,
              ReminderType.specific =>
                CheckinLocalizations.of(context).specificDateReminder,
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
    final weekdays = [
      CheckinLocalizations.of(context).sunday,
      CheckinLocalizations.of(context).monday,
      CheckinLocalizations.of(context).tuesday,
      CheckinLocalizations.of(context).wednesday,
      CheckinLocalizations.of(context).thursday,
      CheckinLocalizations.of(context).friday,
      CheckinLocalizations.of(context).saturday,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _reminderSettings?.weekdays.contains(index) ?? false;
        return FilterChip(
          label: Text(weekdays[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              final List<int> newWeekdays = List.from(
                _reminderSettings?.weekdays ?? [],
              );
              if (selected) {
                newWeekdays.add(index);
              } else {
                newWeekdays.remove(index);
              }
              _reminderSettings = ReminderSettings(
                type: ReminderType.weekly,
                weekdays: newWeekdays,
                timeOfDay: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
              );
            });
          },
        );
      }),
    );
  }

  // 月份日期选择器
  Widget _buildMonthDaySelector() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: CheckinLocalizations.of(context).monthlyReminderDayLabel,
        border: const OutlineInputBorder(),
      ),
      value: _reminderSettings?.dayOfMonth,
      items: List.generate(31, (index) {
        return DropdownMenuItem(
          value: index + 1,
          child: Text(
            '${index + 1}${CheckinLocalizations.of(context).daySuffix}',
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
    return ListTile(
      title: Text(
        _reminderSettings?.specificDate != null
            ? DateTimeUtils.formatDate(_reminderSettings!.specificDate!)
            : CheckinLocalizations.of(context).selectDate,
      ),
      trailing: const Icon(Icons.calendar_today),
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
    return ListTile(
      title: Text(
        _reminderSettings?.timeOfDay != null
            ? '${CheckinLocalizations.of(context).selectTime}: ${_reminderSettings!.timeOfDay.format(context)}'
            : CheckinLocalizations.of(context).selectTime,
      ),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _reminderSettings?.timeOfDay ?? TimeOfDay.now(),
        );
        if (time != null) {
          setState(() {
            _reminderSettings = ReminderSettings(
              type: _reminderSettings!.type,
              weekdays: _reminderSettings!.weekdays,
              dayOfMonth: _reminderSettings!.dayOfMonth,
              specificDate: _reminderSettings!.specificDate,
              timeOfDay: time,
            );
          });
        }
      },
    );
  }
}
