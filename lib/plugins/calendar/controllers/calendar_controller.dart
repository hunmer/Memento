import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import '../models/event.dart';
import '../../../core/storage/storage_manager.dart';

class CalendarController extends ChangeNotifier {
  final StorageManager storage;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _completedEvents = [];
  List<CalendarEvent> _systemEvents = [];
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  
  CalendarController(this.storage) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadEvents();
    await _loadSystemCalendars();
  }

  Future<void> _loadSystemCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final List<Calendar> calendars = calendarsResult.data ?? [];
      
      _systemEvents.clear();
      for (var calendar in calendars) {
        if (calendar.id == null) continue;
        
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id,
          RetrieveEventsParams(
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now().add(const Duration(days: 365)),
          ),
        );
        
        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (var event in eventsResult.data!) {
            if (event.title == null || event.start == null) continue;
            
            _systemEvents.add(CalendarEvent(
              id: '${calendar.id}_${event.eventId}',
              title: event.title!,
              description: event.description ?? '',
              startTime: event.start!,
              endTime: event.end,
              icon: Icons.calendar_today,
              color: _getColorForCalendar(calendar.id!),
              source: 'system_${calendar.id}',
            ));
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading system calendars: $e');
    }
  }

  Color _getColorForCalendar(String calendarId) {
    // 根据日历ID生成固定的颜色
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    
    int hash = 0;
    for (var i = 0; i < calendarId.length; i++) {
      hash = calendarId.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;
  List<CalendarEvent> get events {
    final activeEvents = _events.where((e) => e.completedTime == null).toList();
    return [...activeEvents, ..._systemEvents];
  }
  List<CalendarEvent> get completedEvents => _completedEvents;

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    notifyListeners();
  }

  Future<void> _loadEvents() async {
    try {
      final String eventsJson = await storage.readFile('calendar_events', '[]');
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      final allEvents = eventsList.map((e) => CalendarEvent.fromJson(e)).toList();
      
      // 分离已完成和未完成的事件
      _events = allEvents.where((e) => e.completedTime == null).toList();
      _completedEvents = allEvents.where((e) => e.completedTime != null).toList()
        ..sort((a, b) => b.completedTime!.compareTo(a.completedTime!));
      
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
    notifyListeners();
  }

  Future<void> _saveEvents() async {
    try {
      final allEvents = [..._events, ..._completedEvents];
      final String eventsJson = jsonEncode(allEvents.map((e) => e.toJson()).toList());
      await storage.writeFile('calendar_events', eventsJson);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    _events.add(event);
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    await _saveEvents();
    notifyListeners();
  }

  Future<void> updateEvent(CalendarEvent updatedEvent) async {
    // 只允许更新source为'default'的事件
    if (updatedEvent.source != 'default') {
      debugPrint('Cannot update system calendar event');
      return;
    }
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
      await _saveEvents();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    // 只允许删除source为'default'的事件
    if (event.source != 'default') {
      debugPrint('Cannot delete system calendar event');
      return;
    }
    _events.removeWhere((e) => e.id == event.id);
    _completedEvents.removeWhere((e) => e.id == event.id);
    await _saveEvents();
    notifyListeners();
  }

  Future<void> completeEvent(CalendarEvent event) async {
    // 只允许完成source为'default'的事件
    if (event.source != 'default') {
      debugPrint('Cannot complete system calendar event');
      return;
    }
    // 从活动事件列表中移除
    _events.removeWhere((e) => e.id == event.id);
    // 标记完成时间
    final completedEvent = CalendarEvent(
      id: event.id,
      title: event.title,
      icon: event.icon,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      color: event.color,
      completedTime: DateTime.now(),
    );
    // 添加到已完成事件列表
    _completedEvents.insert(0, completedEvent);
    await _saveEvents();
    notifyListeners();
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return events.where((event) {
      final bool isSameDay = event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
          
      if (event.endTime != null) {
        // 处理跨天事件
        return day.isAfter(event.startTime.subtract(const Duration(days: 1))) &&
            day.isBefore(event.endTime!.add(const Duration(days: 1)));
      }
      
      return isSameDay;
    }).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}