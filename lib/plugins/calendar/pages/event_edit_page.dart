import 'package:flutter/material.dart';
import '../models/event.dart';
import '../../../widgets/circle_icon_picker.dart';

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
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _startDate = event?.startTime ?? widget.initialDate;
    _startTime = TimeOfDay.fromDateTime(event?.startTime ?? widget.initialDate);
    if (event?.endTime != null) {
      _endDate = event!.endTime;
      _endTime = TimeOfDay.fromDateTime(event.endTime!);
    }
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
      initialDateRange: _endDate != null 
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
        if (_endTime == null) {
          _endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择日期范围')),
      );
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
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事件标题')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间不能早于开始时间')),
      );
      return;
    }

    final event = CalendarEvent(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: startDateTime,
      endTime: endDateTime, // 现在endDateTime总是有值
      icon: _selectedIcon,
      color: _selectedColor,
    );

    widget.onSave(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '新建事件' : '编辑事件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
          ),
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
              onColorSelected: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '事件标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '事件描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('日期范围'),
              subtitle: Text(
                _endDate != null
                    ? '${_startDate.year}-${_startDate.month}-${_startDate.day} 至 ${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                    : '${_startDate.year}-${_startDate.month}-${_startDate.day}',
              ),
              onTap: _selectDateRange,
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('开始时间'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: _selectStartTime,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('结束时间'),
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