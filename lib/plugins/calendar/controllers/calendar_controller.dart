import 'package:flutter/material.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../core/services/plugin_widget_sync_helper.dart';
import '../models/event.dart';
import '../services/todo_event_service.dart';

/// 日历总控制器，负责管理日历的所有状态和服务
class CalendarController extends ChangeNotifier {
  final StorageManager _storage;
  final List<CalendarEvent> _events = [];
  final List<CalendarEvent> _completedEvents = [];
  TodoEventService? _todoEventService;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  CalendarController(this._storage) {
    _loadEvents();
  }

  // 获取TodoEventService
  TodoEventService? get todoEventService => _todoEventService;

  // 设置TodoEventService
  void setTodoEventService(TodoEventService service) {
    _todoEventService = service;
    notifyListeners();
  }

  // 获取所有事件
  List<CalendarEvent> get events => List.unmodifiable(_events);

  // 获取已完成事件
  List<CalendarEvent> get completedEvents =>
      List.unmodifiable(_completedEvents);

  // 获取选中的日期
  DateTime get selectedDate => _selectedDate;

  // 获取当前聚焦的月份
  DateTime get focusedMonth => _focusedMonth;

  // 选择日期
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // 设置聚焦月份
  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    notifyListeners();
  }

  // 添加事件
  void addEvent(CalendarEvent event) {
    _events.add(event);
    _saveEvents();
    notifyListeners();

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 更新事件
  void updateEvent(CalendarEvent updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _saveEvents();
      notifyListeners();

      // 同步小组件数据
      PluginWidgetSyncHelper.instance.syncCalendar();
    }
  }

  // 删除事件
  void deleteEvent(CalendarEvent event) {
    _events.removeWhere((e) => e.id == event.id);
    _saveEvents();
    notifyListeners();

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 完成事件
  void completeEvent(CalendarEvent event) {
    final completedEvent = event.copyWith(completedTime: DateTime.now());
    _events.removeWhere((e) => e.id == event.id);
    _completedEvents.add(completedEvent);
    _saveEvents();
    notifyListeners();

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 加载事件
  Future<void> _loadEvents() async {
    try {
      final data = await _storage.read('calendar/calendar_events');
      if (data.isNotEmpty) {
        final List<dynamic> eventsData = data['events'] ?? [];
        final List<dynamic> completedEventsData = data['completedEvents'] ?? [];

        _events.clear();
        _completedEvents.clear();

        _events.addAll(eventsData.map((e) => CalendarEvent.fromJson(e)));
        _completedEvents.addAll(
          completedEventsData.map((e) => CalendarEvent.fromJson(e)),
        );
      }
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
    }
    notifyListeners();
  }

  // 保存事件
  Future<void> _saveEvents() async {
    try {
      await _storage.write('calendar/calendar_events', {
        'events': _events.map((e) => e.toJson()).toList(),
        'completedEvents': _completedEvents.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving calendar events: $e');
    }
  }

  // 获取所有事件（包括Todo任务事件）
  List<CalendarEvent> getAllEvents() {
    final List<CalendarEvent> allEvents = [
      ..._events,
      if (_todoEventService != null) ..._todoEventService!.getTaskEvents(),
    ];
    return allEvents;
  }

  // 手动触发刷新（用于外部事件变化时通知监听者）
  void refresh() {
    notifyListeners();
  }
}
