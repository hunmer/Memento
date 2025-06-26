import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BackupTimePicker extends StatefulWidget {
  final Function(BackupSchedule) onScheduleSelected;
  final BackupSchedule? initialSchedule;

  const BackupTimePicker({
    super.key,
    required this.onScheduleSelected,
    this.initialSchedule,
  });

  @override
  State<BackupTimePicker> createState() => _BackupTimePickerState();
}

class _BackupTimePickerState extends State<BackupTimePicker> {
  late BackupScheduleType _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late List<int> _selectedDays;
  late List<int> _selectedMonthDays;

  @override
  void initState() {
    super.initState();
    if (widget.initialSchedule != null) {
      _selectedType = widget.initialSchedule!.type;
      _selectedDate = widget.initialSchedule!.date;
      _selectedTime = widget.initialSchedule!.time;
      _selectedDays = List.from(widget.initialSchedule!.days);
      _selectedMonthDays = List.from(widget.initialSchedule!.monthDays);
    } else {
      _selectedType = BackupScheduleType.specificDate;
      _selectedDays = [];
      _selectedMonthDays = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.setBackupSchedule),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildScheduleOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _confirmSelection,
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButton<BackupScheduleType>(
      value: _selectedType,
      onChanged: (type) => setState(() => _selectedType = type!),
      items:
          BackupScheduleType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.displayName));
          }).toList(),
    );
  }

  Widget _buildScheduleOptions() {
    switch (_selectedType) {
      case BackupScheduleType.specificDate:
        return _buildDatePicker();
      case BackupScheduleType.daily:
        return _buildTimePicker();
      case BackupScheduleType.weekly:
        return Column(children: [_buildTimePicker(), _buildDaySelector()]);
      case BackupScheduleType.monthly:
        return Column(children: [_buildTimePicker(), _buildMonthDaySelector()]);
    }
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text(
        _selectedDate == null
            ? '选择日期'
            : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      title: Text(
        _selectedTime == null
            ? '选择时间'
            : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      children: List.generate(7, (index) {
        final day = index + 1;
        return ChoiceChip(
          label: Text(_getDayName(day)),
          selected: _selectedDays.contains(day),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildMonthDaySelector() {
    return Wrap(
      children: List.generate(31, (index) {
        final day = index + 1;
        return ChoiceChip(
          label: Text(AppLocalizations.of(context)!.day(day.toString())),
          selected: _selectedMonthDays.contains(day),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMonthDays.add(day);
              } else {
                _selectedMonthDays.remove(day);
              }
            });
          },
        );
      }),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '';
    }
  }

  void _confirmSelection() {
    final schedule = BackupSchedule(
      type: _selectedType,
      date: _selectedDate,
      time: _selectedTime,
      days: _selectedDays,
      monthDays: _selectedMonthDays,
    );
    widget.onScheduleSelected(schedule);
    Navigator.pop(context);
  }
}

enum BackupScheduleType {
  specificDate('指定日期'),
  daily('每天'),
  weekly('每周指定日'),
  monthly('每月指定日');

  final String displayName;
  const BackupScheduleType(this.displayName);
}

class BackupSchedule {
  final BackupScheduleType type;
  final DateTime? date;
  final TimeOfDay? time;
  final List<int> days;
  final List<int> monthDays;

  BackupSchedule({
    required this.type,
    this.date,
    this.time,
    this.days = const [],
    this.monthDays = const [],
  });
}
