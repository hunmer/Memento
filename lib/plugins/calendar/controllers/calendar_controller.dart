import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../../../core/storage/storage_manager.dart';

class CalendarController extends ChangeNotifier {
  final StorageManager storage;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _completedEvents = [];
  
  CalendarController(this.storage) {
    _loadEvents();
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;
  List<CalendarEvent> get events => _events.where((e) => e.completedTime == null).toList();
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
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
      await _saveEvents();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
    _completedEvents.removeWhere((e) => e.id == event.id);
    await _saveEvents();
    notifyListeners();
  }

  Future<void> completeEvent(CalendarEvent event) async {
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