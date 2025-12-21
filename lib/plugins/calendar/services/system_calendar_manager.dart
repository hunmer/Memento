import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/event.dart';

/// 系统日历管理器
/// 负责与设备系统日历进行同步
class SystemCalendarManager {
  static SystemCalendarManager? _instance;
  static SystemCalendarManager get instance => _instance ??= SystemCalendarManager._();

  SystemCalendarManager._();

  late DeviceCalendarPlugin _deviceCalendar;
  String? _calendarId;
  bool _isInitialized = false;

  /// 初始化系统日历管理器
  Future<bool> initialize() async {
    try {
      _deviceCalendar = DeviceCalendarPlugin();
      debugPrint('SystemCalendarManager: 开始初始化...');

      // 请求日历权限
      final permissionsGranted = await _deviceCalendar.requestPermissions();
      if (!permissionsGranted.isSuccess) {
        debugPrint('SystemCalendarManager: 日历权限被拒绝');
        return false;
      }

      debugPrint('SystemCalendarManager: 权限验证成功');

      // 获取或创建 Memento 日历
      _calendarId = await _getOrCreateMementoCalendar();
      if (_calendarId == null) {
        debugPrint('SystemCalendarManager: 无法获取或创建日历');
        return false;
      }

      _isInitialized = true;
      debugPrint('SystemCalendarManager: 初始化成功，日历ID: $_calendarId');
      return true;
    } catch (e) {
      debugPrint('SystemCalendarManager: 初始化失败: $e');
      return false;
    }
  }

  /// 获取或创建 Memento 日历
  Future<String?> _getOrCreateMementoCalendar() async {
    try {
      // 获取所有日历
      final calendars = await _deviceCalendar.retrieveCalendars();
      if (!calendars.isSuccess || calendars.data == null) {
        debugPrint('SystemCalendarManager: 获取日历列表失败');
        return null;
      }

      // 查找名为 "Memento" 的日历
      final mementoCalendar = calendars.data!.firstWhere(
        (calendar) => calendar.name == 'Memento',
        orElse: () => Calendar(),
      );

      // 如果找到 Memento 日历，返回其 ID
      if (mementoCalendar.id != null) {
        debugPrint('SystemCalendarManager: 找到现有 Memento 日历');
        return mementoCalendar.id;
      }

      // 如果没找到，创建新的 Memento 日历
      debugPrint('SystemCalendarManager: 创建新的 Memento 日历');
      final createResult = await _deviceCalendar.createCalendar(
        Calendar(
          name: 'Memento',
          color: const Color(0xFFD35B5B), // 使用日历插件的主题色
          calendarColor: const Color(0xFFD35B5B),
        ),
      );

      if (!createResult.isSuccess || createResult.data == null) {
        debugPrint('SystemCalendarManager: 创建日历失败');
        return null;
      }

      debugPrint('SystemCalendarManager: 创建日历成功，ID: ${createResult.data}');
      return createResult.data;
    } catch (e) {
      debugPrint('SystemCalendarManager: 获取或创建日历失败: $e');
      return null;
    }
  }

  /// 将 CalendarEvent 添加到系统日历
  Future<bool> addEventToSystem(CalendarEvent event) async {
    if (!_isInitialized || _calendarId == null) {
      debugPrint('SystemCalendarManager: 未初始化，无法添加事件');
      return false;
    }

    try {
      final deviceEvent = Event(
        calendarId: _calendarId!,
        title: event.title,
        description: event.description.isEmpty ? null : event.description,
        start: tz.TZDateTime.from(event.startTime, tz.local),
        end: event.endTime != null
            ? tz.TZDateTime.from(event.endTime!, tz.local)
            : tz.TZDateTime.from(
                event.startTime.add(const Duration(hours: 1)),
                tz.local,
              ),
        color: event.color,
        allDay: false,
      );

      // 添加提醒（如果设置了）
      if (event.reminderMinutes != null && event.reminderMinutes! > 0) {
        deviceEvent.reminders = [
          Reminder(
            minutes: event.reminderMinutes!,
          ),
        ];
      }

      final result = await _deviceCalendar.createOrUpdateEvent(deviceEvent);

      if (result.isSuccess && result.data != null) {
        debugPrint('SystemCalendarManager: 事件添加到系统日历成功');
        return true;
      } else {
        debugPrint('SystemCalendarManager: 添加事件失败: ${result.errorMessages}');
        return false;
      }
    } catch (e) {
      debugPrint('SystemCalendarManager: 添加事件异常: $e');
      return false;
    }
  }

  /// 从系统日历删除事件
  Future<bool> deleteEventFromSystem(String eventId) async {
    if (!_isInitialized || _calendarId == null) {
      debugPrint('SystemCalendarManager: 未初始化，无法删除事件');
      return false;
    }

    try {
      final result = await _deviceCalendar.deleteEvent(_calendarId!, eventId);

      if (result.isSuccess) {
        debugPrint('SystemCalendarManager: 从系统日历删除事件成功');
        return true;
      } else {
        debugPrint('SystemCalendarManager: 删除事件失败: ${result.errorMessages}');
        return false;
      }
    } catch (e) {
      debugPrint('SystemCalendarManager: 删除事件异常: $e');
      return false;
    }
  }

  /// 更新系统日历中的事件
  Future<bool> updateEventInSystem(CalendarEvent event) async {
    if (!_isInitialized || _calendarId == null) {
      debugPrint('SystemCalendarManager: 未初始化，无法更新事件');
      return false;
    }

    try {
      // 先删除旧事件
      await deleteEventFromSystem(event.id);

      // 再添加新事件
      return await addEventToSystem(event);
    } catch (e) {
      debugPrint('SystemCalendarManager: 更新事件异常: $e');
      return false;
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取日历 ID
  String? get calendarId => _calendarId;

  /// 检查权限状态
  Future<bool> checkPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      return permissionsGranted.isSuccess && permissionsGranted.data == true;
    } catch (e) {
      debugPrint('SystemCalendarManager: 检查权限异常: $e');
      return false;
    }
  }

  /// 获取系统日历中的所有事件（可选功能）
  Future<List<Event>> getSystemEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || _calendarId == null) {
      return [];
    }

    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now().add(const Duration(days: 365));

      final result = await _deviceCalendar.retrieveEvents(
        _calendarId!,
        tz.TZDateTime.from(start, tz.local),
        tz.TZDateTime.from(end, tz.local),
      );

      if (result.isSuccess && result.data != null) {
        return result.data!;
      }

      return [];
    } catch (e) {
      debugPrint('SystemCalendarManager: 获取系统事件异常: $e');
      return [];
    }
  }
}
