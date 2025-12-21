import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

/// 系统日历管理器
/// 负责与设备系统日历进行同步
class SystemCalendarManager {
  static SystemCalendarManager? _instance;
  static SystemCalendarManager get instance =>
      _instance ??= SystemCalendarManager._();

  SystemCalendarManager._();

  late DeviceCalendarPlugin _deviceCalendar;
  String? _calendarId;
  bool _isInitialized = false;

  // 映射：本地事件ID -> 系统日历中的实际事件ID
  Map<String, String> _localEventIdToSystemEventId = {};

  // 存储键名
  static const String _mappingStorageKey = 'calendar_event_id_mapping';

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

      // 加载持久化的映射关系
      await _loadMapping();

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
        'Memento',
        calendarColor: const Color(0xFFD35B5B), // 使用日历插件的主题色，转换为 int
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
  /// 返回成功时，同时返回系统日历中的实际事件ID
  /// 自动保存本地事件ID到系统事件ID的映射
  Future<MapEntry<bool, String?>> addEventToSystem(CalendarEvent event) async {
    if (!_isInitialized || _calendarId == null) {
      debugPrint('SystemCalendarManager: 未初始化，无法添加事件');
      return MapEntry(false, null);
    }

    try {
      final deviceEvent = Event(
        _calendarId!,
        title: event.title,
        description: event.description.isEmpty ? null : event.description,
        start: tz.TZDateTime.from(event.startTime, tz.local),
        end:
            event.endTime != null
                ? tz.TZDateTime.from(event.endTime!, tz.local)
                : tz.TZDateTime.from(
                  event.startTime.add(const Duration(hours: 1)),
                  tz.local,
                ),
        allDay: false,
      );

      // 添加提醒（如果设置了）
      if (event.reminderMinutes != null && event.reminderMinutes! > 0) {
        deviceEvent.reminders = [Reminder(minutes: event.reminderMinutes!)];
      }

      final result = await _deviceCalendar.createOrUpdateEvent(deviceEvent);

      if (result != null && result.isSuccess && result.data != null) {
        debugPrint('SystemCalendarManager: 事件添加到系统日历成功，实际ID: ${result.data}');
        // 保存映射关系：本地事件ID -> 系统事件ID
        _localEventIdToSystemEventId[event.id] = result.data!;
        return MapEntry(true, result.data);
      }

      final errorMsg = result != null ? result.errors.join(', ') : '未知错误';
      debugPrint('SystemCalendarManager: 添加事件失败: $errorMsg');
      return MapEntry(false, null);
    } catch (e) {
      debugPrint('SystemCalendarManager: 添加事件异常: $e');
      return MapEntry(false, null);
    }
  }

  /// 从系统日历删除事件
  /// eventId 可以是本地事件ID，系统会自动查找对应的系统事件ID
  Future<bool> deleteEventFromSystem(String eventId) async {
    if (!_isInitialized || _calendarId == null) {
      debugPrint('SystemCalendarManager: 未初始化，无法删除事件');
      return false;
    }

    try {
      // 查找系统日历中的真实事件ID
      final systemEventId = _localEventIdToSystemEventId[eventId] ?? eventId;

      // 如果既不是本地映射的ID，也不是直接可用的ID，尝试作为真实ID使用
      final actualEventId = systemEventId;

      if (actualEventId == null || actualEventId.isEmpty) {
        debugPrint('SystemCalendarManager: 无法找到事件ID: $eventId 对应的系统事件ID');
        return false;
      }

      debugPrint('SystemCalendarManager: 尝试删除系统事件，实际ID: $actualEventId');
      final result = await _deviceCalendar.deleteEvent(
        _calendarId!,
        actualEventId,
      );

      if (result != null && result.isSuccess) {
        debugPrint('SystemCalendarManager: 从系统日历删除事件成功');
        // 从映射中移除
        _localEventIdToSystemEventId.remove(eventId);
        return true;
      }

      final errorMsg = result != null ? result.errors.join(', ') : '未知错误';
      debugPrint('SystemCalendarManager: 删除事件失败: $errorMsg');
      return false;
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
      final result = await addEventToSystem(event);
      return result.key;
    } catch (e) {
      debugPrint('SystemCalendarManager: 更新事件异常: $e');
      return false;
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取日历 ID
  String? get calendarId => _calendarId;

  /// 加载持久化的映射关系
  Future<void> _loadMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_mappingStorageKey);
      if (mappingJson != null) {
        final mappingData = jsonDecode(mappingJson) as Map<String, dynamic>;
        _localEventIdToSystemEventId = mappingData.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        debugPrint('SystemCalendarManager: 加载映射关系完成，共 ${_localEventIdToSystemEventId.length} 条');
      }
    } catch (e) {
      debugPrint('SystemCalendarManager: 加载映射关系失败: $e');
    }
  }

  /// 保存映射关系到持久化存储
  Future<void> _saveMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = jsonEncode(_localEventIdToSystemEventId);
      await prefs.setString(_mappingStorageKey, mappingJson);
      debugPrint('SystemCalendarManager: 保存映射关系完成，共 ${_localEventIdToSystemEventId.length} 条');
    } catch (e) {
      debugPrint('SystemCalendarManager: 保存映射关系失败: $e');
    }
  }

  /// 检查权限状态
  Future<bool> checkPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      if (permissionsGranted == null) {
        return false;
      }
      return permissionsGranted.isSuccess == true &&
          permissionsGranted.data == true;
    } catch (e) {
      debugPrint('SystemCalendarManager: 检查权限异常: $e');
      return false;
    }
  }

  /// 获取系统日历中的所有事件（包括 Memento 日历）
  /// 但是会标记来源：来自 Memento 日历的标记为 'memento'，其他的标记为 'system'
  Future<List<CalendarEvent>> getSystemEvents({
    DateTime? startDate,
    DateTime? endDate,
    bool includeMementoCalendar = false, // 是否包含 Memento 日历
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('SystemCalendarManager: 初始化失败，无法获取系统事件');
        return [];
      }
    }

    try {
      // 获取所有日历
      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        debugPrint('SystemCalendarManager: 获取日历列表失败');
        return [];
      }

      final calendars = calendarsResult.data!;
      final List<CalendarEvent> allEvents = [];

      // 默认查询范围：前后1年
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 365));
      final end = endDate ?? now.add(const Duration(days: 365));

      // 遍历所有日历
      for (final calendar in calendars) {
        debugPrint(
          "SystemCalendarManager: 正在处理日历: ${calendar.name} (ID: ${calendar.id})",
        );
        // 如果不包含 Memento 日历，则跳过
        if (!includeMementoCalendar && (calendar.name == 'Memento' || calendar.id == _calendarId)) {
          continue;
        }

        try {
          final eventsResult = await _deviceCalendar.retrieveEvents(
            calendar.id,
            RetrieveEventsParams(startDate: start, endDate: end),
          );

          if (eventsResult.isSuccess && eventsResult.data != null) {
            for (final event in eventsResult.data!) {
              // 标记来源：Memento 日历的事件标记为 'memento'，其他标记为 'system'
              final isFromMemento = calendar.name == 'Memento' || calendar.id == _calendarId;
              final source = isFromMemento ? 'memento' : 'system';

              final calendarEvent = CalendarEvent(
                id: isFromMemento ? 'memento_${calendar.id}_${event.eventId}' : 'system_${calendar.id}_${event.eventId}',
                title: event.title ?? '无标题',
                description: event.description ?? '',
                startTime: event.start?.toLocal() ?? now,
                endTime: event.end?.toLocal(),
                icon: const IconData(
                  0xe935,
                  fontFamily: 'MaterialIcons',
                ), // calendar_today
                color: Color(calendar.color ?? 0xFF2196F3),
                source: source,
                systemEventId: event.eventId, // 保存系统事件ID
              );
              allEvents.add(calendarEvent);
            }
          }
        } catch (e) {
          debugPrint('SystemCalendarManager: 获取日历 ${calendar.name} 事件失败: $e');
        }
      }

      debugPrint('SystemCalendarManager: 获取到 ${allEvents.length} 个系统日历事件');
      return allEvents;
    } catch (e) {
      debugPrint('SystemCalendarManager: 获取系统事件异常: $e');
      return [];
    }
  }
}
