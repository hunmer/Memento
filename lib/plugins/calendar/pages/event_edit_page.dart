import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/widgets/picker/circle_icon_picker.dart';
import 'package:Memento/plugins/calendar/utils/calendar_notification_utils.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/form_fields/index.dart';

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

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前事件编辑状态
  void _updateRouteContext() {
    final isEditing = widget.event != null;
    final dateStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final title = _titleController.text.isEmpty ? '未命名事件' : _titleController.text;

    RouteHistoryManager.updateCurrentContext(
      pageId: isEditing ? '/calendar_event_edit' : '/calendar_event_new',
      title: isEditing ? '编辑事件 - $title' : '新建事件',
      params: {
        'mode': isEditing ? '编辑' : '新建',
        'eventTitle': title,
        'startDate': dateStr,
        if (isEditing) 'eventId': widget.event!.id,
      },
    );
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

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _buildDateRangeSelector() {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _endDate != null
                    ? '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')} 至 ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                    : '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'calendar_dateRange'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSelector() {
    final reminderItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem(value: null, child: Text('不提醒')),
      const DropdownMenuItem(value: 5, child: Text('提前5分钟')),
      const DropdownMenuItem(value: 15, child: Text('提前15分钟')),
      const DropdownMenuItem(value: 30, child: Text('提前30分钟')),
      const DropdownMenuItem(value: 60, child: Text('提前1小时')),
      const DropdownMenuItem(value: 120, child: Text('提前2小时')),
      const DropdownMenuItem(value: 1440, child: Text('提前1天')),
      const DropdownMenuItem(value: 2880, child: Text('提前2天')),
    ];

    return SelectField<int?>(
      value: _reminderMinutes,
      labelText: 'calendar_reminderSettings'.tr,
      items: reminderItems,
      onChanged: (value) {
        setState(() {
          _reminderMinutes = value;
        });
      },
    );
  }

  Widget _buildStartTimeSelector() {
    return TimePickerField(
      label: 'calendar_startTime'.tr,
      time: _startTime,
      onTimeChanged: (time) {
        setState(() {
          _startTime = time;
          // 如果结束时间未设置，默认设置为开始时间后1小时
          _endTime ??= TimeOfDay(
            hour: (time.hour + 1) % 24,
            minute: time.minute,
          );
        });
      },
    );
  }

  Widget _buildEndTimeSelector() {
    return TimePickerField(
      label: 'calendar_endTime'.tr,
      time: _endTime ?? const TimeOfDay(hour: 0, minute: 0),
      onTimeChanged: (time) {
        setState(() {
          _endTime = time;
        });
      },
    );
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
            TextInputField(
              controller: _titleController,
              labelText: 'calendar_eventTitle'.tr,
            ),
            const SizedBox(height: 16),
            TextAreaField(
              controller: _descriptionController,
              hintText: '请输入事件描述',
              labelText: 'calendar_eventDescription'.tr,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _buildDateRangeSelector(),
            const SizedBox(height: 16),
            _buildReminderSelector(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStartTimeSelector(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEndTimeSelector(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
