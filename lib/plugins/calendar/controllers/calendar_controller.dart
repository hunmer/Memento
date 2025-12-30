import 'package:flutter/material.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/calendar/services/system_calendar_manager.dart';
import 'package:Memento/plugins/calendar/services/calendar_mapping_manager.dart';

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
    // cleanupOrphanedSystemEvents();
  }

  /// 加载系统日历事件和映射关系
  Future<void> loadSystemEvents() async {
    try {
      final systemManager = SystemCalendarManager.instance;
      final mappingManager = CalendarMappingManager.instance;

      // 先加载映射关系
      await mappingManager.loadMapping();

      // 获取系统日历事件（包括 Memento 日历）
      _systemEvents = await systemManager.getSystemEvents();

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

    // 触发事件
    _notifyEvent('added', event);

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

      // 触发事件
      _notifyEvent('updated', updatedEvent);

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

    // 触发事件
    _notifyEvent('deleted', event);

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

    // 触发事件
    _notifyEvent('completed', event);

    // 从系统日历删除（已完成的事件不再显示在日历中）
    await _syncDeleteFromSystemCalendar(event);

    // 同步小组件数据
    PluginWidgetSyncHelper.instance.syncCalendar();
  }

  // 触发事件
  void _notifyEvent(String action, CalendarEvent event) {
    final eventArgs = ItemEventArgs(
      eventName: 'calendar_event_$action',
      itemId: event.id,
      title: event.title,
      action: action,
    );
    EventManager.instance.broadcast('calendar_event_$action', eventArgs);
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

    // 使用固定的ID前缀，避免重复创建
    const String sampleIdPrefix = 'sample_event_';

    final sampleEvents = [
      CalendarEvent(
        id: '${sampleIdPrefix}1',
        title: '团队周会',
        description: '每周例会，讨论本周工作进展和下周计划',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        icon: const IconData(
          0xe8df,
          fontFamily: 'MaterialIcons',
        ), // Icons.groups
        color: Colors.blue,
        reminderMinutes: 15,
      ),
      CalendarEvent(
        id: '${sampleIdPrefix}2',
        title: '健身时间',
        description: '下班后去健身房锻炼',
        startTime: DateTime(now.year, now.month, now.day, 18, 30),
        endTime: DateTime(now.year, now.month, now.day, 20, 0),
        icon: const IconData(
          0xeb43,
          fontFamily: 'MaterialIcons',
        ), // Icons.fitness_center
        color: Colors.green,
        reminderMinutes: 30,
      ),
      CalendarEvent(
        id: '${sampleIdPrefix}3',
        title: '朋友生日',
        description: '记得准备生日礼物和蛋糕',
        startTime: DateTime(now.year, now.month, now.day + 3, 19, 0),
        endTime: DateTime(now.year, now.month, now.day + 3, 21, 0),
        icon: const IconData(0xe7f2, fontFamily: 'MaterialIcons'), // Icons.cake
        color: Colors.pink,
        reminderMinutes: 1440, // 提前一天提醒
      ),
      CalendarEvent(
        id: '${sampleIdPrefix}4',
        title: '项目截止日期',
        description: '完成项目文档和代码提交',
        startTime: DateTime(now.year, now.month, now.day + 7, 17, 0),
        endTime: DateTime(now.year, now.month, now.day + 7, 18, 0),
        icon: const IconData(
          0xe873,
          fontFamily: 'MaterialIcons',
        ), // Icons.assignment
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
    final mappingManager = CalendarMappingManager.instance;
    final allMappings = mappingManager.allMappings;

    // 创建系统事件的副本
    final List<CalendarEvent> systemEventsCopy = List.from(_systemEvents);

    // 使用映射关系过滤系统事件：
    // 只排除 calendar 插件自己创建的事件（避免与 _events 重复）
    // 保留 todo 等其他插件创建的事件
    systemEventsCopy.removeWhere((systemEvent) {
      // 方法1：检查映射关系
      for (final mapping in allMappings.values) {
        final systemEventId = mapping['systemId'] as String?;
        final from = mapping['from'] as String?;

        if (systemEventId == systemEvent.systemEventId) {
          // 只排除 calendar 插件自己创建的事件
          if (from == 'calendar') {
            return true; // 排除此事件
          }
          return false;
        }
      }

      // 方法2：即使没有映射关系，也检查是否与本地事件重复
      // 这样可以处理映射关系还没保存完成的情况
      for (final localEvent in _events) {
        // 检查是否是同一个事件（标题、开始时间、结束时间都匹配）
        final isSameEvent =
            systemEvent.title == localEvent.title &&
            _isSameDateTime(systemEvent.startTime, localEvent.startTime) &&
            _isSameDateTime(systemEvent.endTime, localEvent.endTime);

        if (isSameEvent) {
          return true; // 排除此事件
        }
      }

      return false; // 保留此事件
    });

    // 合并事件：系统事件 + 本地事件
    final List<CalendarEvent> allEvents = [
      ...systemEventsCopy, // 其他来源的系统日历事件（包括 todo）
      ..._events, // calendar 插件本地事件
    ];

    return allEvents;
  }

  /// 检查两个日期时间是否相同（忽略毫秒和秒）
  bool _isSameDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
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
      final mappingManager = CalendarMappingManager.instance;

      if (!systemCalendar.isInitialized) {
        final initialized = await systemCalendar.initialize();
        if (!initialized) {
          debugPrint('CalendarController: 系统日历管理器初始化失败，跳过同步');
          return;
        }
      }

      // ✅ 确保映射关系已加载
      await mappingManager.loadMapping();

      // 获取所有未完成的事件（只同步默认来源的事件）
      final eventsToSync = _events.where((e) => e.source == 'default').toList();

      debugPrint('CalendarController: 开始同步 ${eventsToSync.length} 个事件到系统日历');

      int successCount = 0;
      int failedCount = 0;
      int skippedCount = 0;

      // 遍历所有事件，逐一同步
      for (final event in eventsToSync) {
        try {
          // 检查是否已经有映射关系
          final existingSystemId = mappingManager.getSystemEventId(event.id);
          if (existingSystemId != null) {
            skippedCount++;
            continue;
          }

          final result = await systemCalendar.addEventToSystem(event);
          if (result.key && result.value != null) {
            // ✅ 保存映射关系
            await mappingManager.addMapping(
              localId: event.id,
              from: 'calendar',
              data: event.toJson(),
              systemId: result.value!,
            );
            successCount++;
            debugPrint(
              'CalendarController: 事件 "${event.title}" 同步成功，系统ID: ${result.value}',
            );
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
        'CalendarController: 同步完成，成功: $successCount，跳过: $skippedCount，失败: $failedCount',
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
        if (result.key && result.value != null) {
          debugPrint(
            'CalendarController: 事件 "${event.title}" 已同步到系统日历，系统ID: ${result.value}',
          );

          // ✅ 保存映射关系
          final mappingManager = CalendarMappingManager.instance;
          await mappingManager.addMapping(
            localId: event.id,
            from: 'calendar',
            data: event.toJson(),
            systemId: result.value!,
          );
          debugPrint(
            'CalendarController: 映射关系已保存，本地ID: ${event.id} -> 系统ID: ${result.value}',
          );
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
      final mappingManager = CalendarMappingManager.instance;
      if (!systemCalendar.isInitialized) {
        return;
      }

      // 只有默认来源的事件才从系统日历删除
      if (event.source == 'default') {
        // 通过映射关系获取系统日历ID
        final systemEventId = mappingManager.getSystemEventId(event.id);
        if (systemEventId != null) {
          final success = await systemCalendar.deleteEventFromSystem(
            systemEventId,
          );
          if (success) {
            debugPrint('CalendarController: 事件 "${event.title}" 已从系统日历删除');

            // 删除映射关系
            await mappingManager.removeMapping(event.id);
          } else {
            debugPrint('CalendarController: 事件 "${event.title}" 从系统日历删除失败');
          }
        } else {
          debugPrint('CalendarController: 未找到事件 "${event.title}" 的映射关系');
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
      final mappingManager = CalendarMappingManager.instance;

      if (!systemCalendar.isInitialized) {
        return;
      }

      // 只有默认来源的事件才更新到系统日历
      if (newEvent.source == 'default') {
        // 先删除旧的系统事件
        final oldSystemEventId = mappingManager.getSystemEventId(oldEvent.id);
        if (oldSystemEventId != null) {
          await systemCalendar.deleteEventFromSystem(oldSystemEventId);
          await mappingManager.removeMapping(oldEvent.id);
          debugPrint('CalendarController: 已删除旧的系统事件，ID: $oldSystemEventId');
        }

        // 添加新的系统事件
        final result = await systemCalendar.addEventToSystem(newEvent);
        if (result.key && result.value != null) {
          // 保存新的映射关系
          await mappingManager.addMapping(
            localId: newEvent.id,
            from: 'calendar',
            data: newEvent.toJson(),
            systemId: result.value!,
          );
          debugPrint(
            'CalendarController: 事件 "${newEvent.title}" 已更新到系统日历，新系统ID: ${result.value}',
          );
        } else {
          debugPrint('CalendarController: 事件 "${newEvent.title}" 更新到系统日历失败');
        }
      }
    } catch (e) {
      debugPrint('CalendarController: 更新系统日历事件异常: $e');
    }
  }

  /// 清理系统日历中的孤立事件（没有对应映射关系的事件）
  /// 注意：此方法会删除所有在 Memento 日历中但没有映射关系的事件
  Future<void> cleanupOrphanedSystemEvents() async {
    try {
      final systemCalendar = SystemCalendarManager.instance;
      final mappingManager = CalendarMappingManager.instance;

      if (!systemCalendar.isInitialized) {
        await systemCalendar.initialize();
      }

      // 加载映射关系
      await mappingManager.loadMapping();
      final allMappings = mappingManager.allMappings;

      // 获取系统日历中的所有事件
      final systemEvents = await systemCalendar.getSystemEvents();

      int deletedCount = 0;
      int keptCount = 0;

      // 检查每个系统事件是否有对应的映射关系
      for (final event in systemEvents) {
        if (event.systemEventId == null) {
          keptCount++;
          continue;
        }

        // 查找是否有映射关系指向这个系统事件
        bool hasMapping = false;
        for (final mapping in allMappings.values) {
          final systemId = mapping['systemId'] as String?;
          if (systemId == event.systemEventId) {
            hasMapping = true;
            break;
          }
        }

        // 如果没有映射关系，且来源是 system，则删除（孤立事件）
        if (!hasMapping && event.source == 'system') {
          final success = await systemCalendar.deleteEventFromSystem(
            event.systemEventId!,
          );
          if (success) {
            deletedCount++;
            debugPrint(
              'CalendarController: 删除孤立的系统事件 "${event.title}" (${event.systemEventId})',
            );
          }
        } else {
          keptCount++;
        }
      }

      debugPrint(
        'CalendarController: 清理完成，删除 $deletedCount 个孤立事件，保留 $keptCount 个事件',
      );
    } catch (e) {
      debugPrint('CalendarController: 清理孤立事件异常: $e');
    }
  }
}
