import 'package:flutter/material.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/calendar/services/system_calendar_manager.dart';

/// 日历总控制器，负责管理日历的所有状态和服务
class CalendarController extends ChangeNotifier {
  final StorageManager _storage;
  final List<CalendarEvent> _events = [];
  final List<CalendarEvent> _completedEvents = [];
  List<CalendarEvent> _systemEvents = []; // 系统日历事件缓存
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  CalendarController(this._storage) {
    _loadEvents();
  }

  /// 加载系统日历事件
  Future<void> loadSystemEvents() async {
    try {
      final systemManager = SystemCalendarManager.instance;
      _systemEvents = await systemManager.getSystemEvents(includeMementoCalendar: true);
      debugPrint('CalendarController: 加载系统日历事件完成，共 ${_systemEvents.length} 个事件');
      for (final event in _systemEvents) {
        debugPrint('CalendarController: 系统事件 - ID: ${event.id}, 标题: ${event.title}, 来源: ${event.source}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('CalendarController: 加载系统日历事件失败: $e');
    }
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
  void addEvent(CalendarEvent event) async {
    _events.add(event);
    await _saveEvents();
    notifyListeners();

    // 同步到系统日历
    _syncToSystemCalendar(event);

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 更新事件
  void updateEvent(CalendarEvent updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      final oldEvent = _events[index];
      _events[index] = updatedEvent;
      await _saveEvents();
      notifyListeners();

      // 同步到系统日历
      await _syncUpdateToSystemCalendar(oldEvent, updatedEvent);

      // 同步小组件数据
      PluginWidgetSyncHelper.instance.syncCalendar();
    }
  }

  // 删除事件
  void deleteEvent(CalendarEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
    await _saveEvents();
    notifyListeners();

    // 从系统日历删除
    await _syncDeleteFromSystemCalendar(event);

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 完成事件
  void completeEvent(CalendarEvent event) async {
    final completedEvent = event.copyWith(completedTime: DateTime.now());
    _events.removeWhere((e) => e.id == event.id);
    _completedEvents.add(completedEvent);
    await _saveEvents();
    notifyListeners();

    // 从系统日历删除（已完成的事件不再显示在日历中）
    await _syncDeleteFromSystemCalendar(event);

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
      } else {
        // 文件不存在或为空，创建示例事件
        await _createSampleEvents();
      }
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
      // 加载失败时也尝试创建示例事件
      await _createSampleEvents();
    }
    notifyListeners();

    // 同步所有现有事件到系统日历（异步执行，不阻塞 UI）
    _syncAllEventsToSystemCalendar();
  }

  // 创建示例事件
  Future<void> _createSampleEvents() async {
    final now = DateTime.now();

    final sampleEvents = [
      CalendarEvent(
        id: now.millisecondsSinceEpoch.toString(),
        title: '团队周会',
        description: '每周例会，讨论本周工作进展和下周计划',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        icon: const IconData(0xe8df, fontFamily: 'MaterialIcons'), // Icons.groups
        color: Colors.blue,
        reminderMinutes: 15,
      ),
      CalendarEvent(
        id: (now.millisecondsSinceEpoch + 1).toString(),
        title: '健身时间',
        description: '下班后去健身房锻炼',
        startTime: DateTime(now.year, now.month, now.day, 18, 30),
        endTime: DateTime(now.year, now.month, now.day, 20, 0),
        icon: const IconData(0xeb43, fontFamily: 'MaterialIcons'), // Icons.fitness_center
        color: Colors.green,
        reminderMinutes: 30,
      ),
      CalendarEvent(
        id: (now.millisecondsSinceEpoch + 2).toString(),
        title: '朋友生日',
        description: '记得准备生日礼物和蛋糕',
        startTime: DateTime(now.year, now.month, now.day + 3, 19, 0),
        endTime: DateTime(now.year, now.month, now.day + 3, 21, 0),
        icon: const IconData(0xe7f2, fontFamily: 'MaterialIcons'), // Icons.cake
        color: Colors.pink,
        reminderMinutes: 1440, // 提前一天提醒
      ),
      CalendarEvent(
        id: (now.millisecondsSinceEpoch + 3).toString(),
        title: '项目截止日期',
        description: '完成项目文档和代码提交',
        startTime: DateTime(now.year, now.month, now.day + 7, 17, 0),
        endTime: DateTime(now.year, now.month, now.day + 7, 18, 0),
        icon: const IconData(0xe873, fontFamily: 'MaterialIcons'), // Icons.assignment
        color: Colors.orange,
        reminderMinutes: 2880, // 提前两天提醒
      ),
    ];

    _events.addAll(sampleEvents);
    await _saveEvents();
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

  // 获取所有事件（包括本地事件和系统日历事件）
  List<CalendarEvent> getAllEvents() {
    final List<CalendarEvent> allEvents = [
      ..._events,
      ..._systemEvents, // 包含来自系统日历的所有事件（包括 Memento 日历中的 todo 任务）
    ];

    return allEvents;
  }

  // 手动触发刷新（用于外部事件变化时通知监听者）
  void refresh() {
    notifyListeners();
  }

  // ========== 系统日历同步方法 ==========

  /// 同步所有现有事件到系统日历（初始化时调用）
  Future<void> _syncAllEventsToSystemCalendar() async {
    try {
      final systemCalendar = SystemCalendarManager.instance;
      if (!systemCalendar.isInitialized) {
        final initialized = await systemCalendar.initialize();
        if (!initialized) {
          debugPrint('CalendarController: 系统日历管理器初始化失败，跳过同步');
          return;
        }
      }

      // 获取所有未完成的事件（只同步默认来源的事件）
      final eventsToSync = _events.where((e) => e.source == 'default').toList();

      debugPrint('CalendarController: 开始同步 ${eventsToSync.length} 个事件到系统日历');

      int successCount = 0;
      int failedCount = 0;

      // 遍历所有事件，逐一同步
      for (final event in eventsToSync) {
        try {
          final result = await systemCalendar.addEventToSystem(event);
          if (result.key) {
            successCount++;
            debugPrint('CalendarController: 事件 "${event.title}" 同步成功');
          } else {
            failedCount++;
            debugPrint('CalendarController: 事件 "${event.title}" 同步失败');
          }
        } catch (e) {
          failedCount++;
          debugPrint('CalendarController: 同步事件 "${event.title}" 异常: $e');
        }

        // 添加小延迟，避免过于频繁的 API 调用
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint(
        'CalendarController: 同步完成，成功: $successCount，失败: $failedCount',
      );
    } catch (e) {
      debugPrint('CalendarController: 同步所有事件到系统日历异常: $e');
    }
  }

  /// 同步事件到系统日历
  Future<void> _syncToSystemCalendar(CalendarEvent event) async {
    try {
      final systemCalendar = SystemCalendarManager.instance;
      if (!systemCalendar.isInitialized) {
        final initialized = await systemCalendar.initialize();
        if (!initialized) {
          debugPrint('CalendarController: 系统日历管理器初始化失败，跳过同步');
          return;
        }
      }

      // 只有默认来源的事件才同步到系统日历
      if (event.source == 'default') {
        final result = await systemCalendar.addEventToSystem(event);
        if (result.key) {
          debugPrint('CalendarController: 事件 "${event.title}" 已同步到系统日历');
        } else {
          debugPrint('CalendarController: 事件 "${event.title}" 同步到系统日历失败');
        }
      }
    } catch (e) {
      debugPrint('CalendarController: 同步事件到系统日历异常: $e');
    }
  }

  /// 从系统日历删除事件
  Future<void> _syncDeleteFromSystemCalendar(CalendarEvent event) async {
    try {
      final systemCalendar = SystemCalendarManager.instance;
      if (!systemCalendar.isInitialized) {
        return;
      }

      // 只有默认来源的事件才从系统日历删除
      if (event.source == 'default') {
        final success = await systemCalendar.deleteEventFromSystem(event.id);
        if (success) {
          debugPrint('CalendarController: 事件 "${event.title}" 已从系统日历删除');
        } else {
          debugPrint('CalendarController: 事件 "${event.title}" 从系统日历删除失败');
        }
      }
    } catch (e) {
      debugPrint('CalendarController: 从系统日历删除事件异常: $e');
    }
  }

  /// 更新系统日历中的事件
  Future<void> _syncUpdateToSystemCalendar(
    CalendarEvent oldEvent,
    CalendarEvent newEvent,
  ) async {
    try {
      final systemCalendar = SystemCalendarManager.instance;
      if (!systemCalendar.isInitialized) {
        return;
      }

      // 只有默认来源的事件才更新到系统日历
      if (newEvent.source == 'default') {
        final success = await systemCalendar.updateEventInSystem(newEvent);
        if (success) {
          debugPrint('CalendarController: 事件 "${newEvent.title}" 已更新到系统日历');
        } else {
          debugPrint('CalendarController: 事件 "${newEvent.title}" 更新到系统日历失败');
        }
      }
    } catch (e) {
      debugPrint('CalendarController: 更新系统日历事件异常: $e');
    }
  }
}
