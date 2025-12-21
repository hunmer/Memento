import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:Memento/plugins/calendar/utils/calendar_notification_utils.dart';
import 'package:Memento/core/services/toast_service.dart';

class EventEditPage extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime initialDate;
  final Function(CalendarEvent) onSave;

  const EventEditPage({
    super.key,
    this.event,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  String _getReminderText(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return '提前$days天';
    } else if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '提前$hours小时';
    } else {
      return '提前$minutes分钟';
    }
  }

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  int? _reminderMinutes;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _startDate = event?.startTime ?? widget.initialDate;
    _startTime = TimeOfDay.fromDateTime(event?.startTime ?? widget.initialDate);
    if (event?.endTime != null) {
      _endDate = event!.endTime;
      _endTime = TimeOfDay.fromDateTime(event.endTime!);
    }
    _reminderMinutes = event?.reminderMinutes;
    _selectedIcon = event?.icon ?? Icons.event;
    _selectedColor = event?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _endDate != null
              ? DateTimeRange(start: _startDate, end: _endDate!)
              : DateTimeRange(start: _startDate, end: _startDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // 如果结束时间未设置，默认设置为开始时间后1小时
        _endTime ??= TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      });
    }
  }

  Future<void> _selectReminderMinutes() async {
    final items = [
      {'label': '不提醒', 'value': null},
      {'label': '提前5分钟', 'value': 5},
      {'label': '提前15分钟', 'value': 15},
      {'label': '提前30分钟', 'value': 30},
      {'label': '提前1小时', 'value': 60},
      {'label': '提前2小时', 'value': 120},
      {'label': '提前1天', 'value': 1440},
      {'label': '提前2天', 'value': 2880},
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('calendar_selectReminderTime'.tr),
          children:
              items
                  .map(
                    (item) => SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, item['value'] as int?);
                      },
                      child: Text(item['label'] as String),
                    ),
                  )
                  .toList(),
        );
      },
    );

    if (result != null) {
      setState(() {
        _reminderMinutes = result;
      });
    }
  }

  Future<void> _selectEndTime() async {
    if (_endDate == null) {
      toastService.showToast('calendar_selectDateRangeFirst'.tr);
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty) {
      toastService.showToast('calendar_enterEventTitle'.tr);
      return;
    }

    final startDateTime = _combineDateAndTime(_startDate, _startTime);

    // 确保总是有结束时间
    DateTime endDateTime;
    if (_endDate != null) {
      // 如果设置了结束日期但没有结束时间，使用开始时间
      TimeOfDay effectiveEndTime = _endTime ?? _startTime;
      endDateTime = _combineDateAndTime(_endDate!, effectiveEndTime);
    } else {
      // 如果没有设置结束日期，默认为开始日期加1小时
      endDateTime = startDateTime.add(const Duration(hours: 1));
    }

    if (endDateTime.isBefore(startDateTime)) {
      toastService.showToast('calendar_endTimeCannotBeEarlier'.tr);
      return;
    }

    final event = CalendarEvent(
      id: widget.event?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: startDateTime,
      endTime: endDateTime, // 现在endDateTime总是有值
      icon: _selectedIcon,
      color: _selectedColor,
      reminderMinutes: _reminderMinutes,
      source: 'default',
    );

    // 设置提醒
    if (_reminderMinutes != null) {
      final reminderTime = startDateTime.subtract(
        Duration(minutes: _reminderMinutes!),
      );
      if (reminderTime.isAfter(DateTime.now())) {
        await CalendarNotificationUtils.scheduleEventNotification(
          id: int.parse(event.id), // 确保ID是整数
          title: event.title,
          body: event.description,
          scheduledDateTime: reminderTime,
          payload: event.id,
        );
      }
    }

    widget.onSave(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '新建事件' : '编辑事件'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEvent),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIconPicker(
              currentIcon: _selectedIcon,
              backgroundColor: _selectedColor,
              onIconSelected: (icon) => setState(() => _selectedIcon = icon),
              onColorSelected:
                  (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'calendar_eventTitle'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'calendar_eventDescription'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('calendar_dateRange'.tr),
              subtitle: Text(
                _endDate != null
                    ? '${_startDate.year}-${_startDate.month}-${_startDate.day} 至 ${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                    : '${_startDate.year}-${_startDate.month}-${_startDate.day}',
              ),
              onTap: _selectDateRange,
            ),
            ListTile(
              title: Text('calendar_reminderSettings'.tr),
              subtitle: Text(
                _reminderMinutes != null
                    ? _getReminderText(_reminderMinutes!)
                    : '不提醒',
              ),
              trailing:
                  _reminderMinutes != null
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed:
                            () => setState(() => _reminderMinutes = null),
                      )
                      : null,
              onTap: _selectReminderMinutes,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('calendar_startTime'.tr),
                    subtitle: Text(_startTime.format(context)),
                    onTap: _selectStartTime,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('calendar_endTime'.tr),
                    subtitle: Text(_endTime?.format(context) ?? '无'),
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
