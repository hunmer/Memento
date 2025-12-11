/// Calendar 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerCalendarRepository implements ICalendarRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'calendar';

  ServerCalendarRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<Map<String, dynamic>?> _readAllEvents() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'calendar_events.json',
    );
    return data;
  }

  Future<void> _saveAllEvents(Map<String, dynamic> data) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'calendar_events.json',
      data,
    );
  }

  Future<List<CalendarEventDto>> _parseEvents(
      Map<String, dynamic>? data) async {
    if (data == null) return [];

    final events = data['events'] as List<dynamic>? ?? [];
    return events
        .map((e) => CalendarEventDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarEventDto>> _parseCompletedEvents(
      Map<String, dynamic>? data) async {
    if (data == null) return [];

    final completedEvents = data['completedEvents'] as List<dynamic>? ?? [];
    return completedEvents
        .map((e) => CalendarEventDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============ 事件操作实现 ============

  @override
  Future<Result<List<CalendarEventDto>>> getEvents(
      {PaginationParams? pagination}) async {
    try {
      final data = await _readAllEvents();
      var events = await _parseEvents(data);

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          events,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(events);
    } catch (e) {
      return Result.failure('获取事件列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto?>> getEventById(String id) async {
    try {
      final data = await _readAllEvents();
      final events = await _parseEvents(data);
      final event = events.where((e) => e.id == id).firstOrNull;
      return Result.success(event);
    } catch (e) {
      return Result.failure('获取事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto>> createEvent(CalendarEventDto event) async {
    try {
      final data = await _readAllEvents();
      final events = await _parseEvents(data);
      events.add(event);
      await _saveAllEvents({
        'events': events.map((e) => e.toJson()).toList(),
        'completedEvents': (data?['completedEvents'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      });
      return Result.success(event);
    } catch (e) {
      return Result.failure('创建事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto>> updateEvent(
      String id, CalendarEventDto event) async {
    try {
      final data = await _readAllEvents();
      final events = await _parseEvents(data);
      final index = events.indexWhere((e) => e.id == id);

      if (index == -1) {
        return Result.failure('事件不存在', code: ErrorCodes.notFound);
      }

      events[index] = event;
      await _saveAllEvents({
        'events': events.map((e) => e.toJson()).toList(),
        'completedEvents': (data?['completedEvents'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      });
      return Result.success(event);
    } catch (e) {
      return Result.failure('更新事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteEvent(String id) async {
    try {
      final data = await _readAllEvents();
      final events = await _parseEvents(data);
      final initialLength = events.length;
      events.removeWhere((e) => e.id == id);

      if (events.length == initialLength) {
        return Result.failure('事件不存在', code: ErrorCodes.notFound);
      }

      await _saveAllEvents({
        'events': events.map((e) => e.toJson()).toList(),
        'completedEvents': (data?['completedEvents'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      });

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto>> completeEvent(
      String id, DateTime completedTime) async {
    try {
      final data = await _readAllEvents();
      final events = await _parseEvents(data);
      final index = events.indexWhere((e) => e.id == id);

      if (index == -1) {
        return Result.failure('事件不存在', code: ErrorCodes.notFound);
      }

      final completedEvents = await _parseCompletedEvents(data);

      final event = events[index];
      final completedEvent = event.copyWith(
        completedTime: completedTime,
        updatedAt: DateTime.now(),
      );

      events.removeAt(index);
      completedEvents.add(completedEvent);

      await _saveAllEvents({
        'events': events.map((e) => e.toJson()).toList(),
        'completedEvents': completedEvents.map((e) => e.toJson()).toList(),
      });

      return Result.success(completedEvent);
    } catch (e) {
      return Result.failure('完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CalendarEventDto>>> searchEvents(
      CalendarEventQuery query) async {
    try {
      final data = await _readAllEvents();
      var events = await _parseEvents(data);

      // 按日期范围过滤
      if (query.startDate != null) {
        events = events.where((event) {
          return event.startTime.isAfter(query.startDate!) ||
              event.startTime.isAtSameMomentAs(query.startDate!);
        }).toList();
      }

      if (query.endDate != null) {
        events = events.where((event) {
          return event.startTime.isBefore(query.endDate!) ||
              event.startTime.isAtSameMomentAs(query.endDate!);
        }).toList();
      }

      // 按来源过滤
      if (query.source != null) {
        events = events.where((event) => event.source == query.source).toList();
      }

      // 按标题关键词过滤
      if (query.titleKeyword != null) {
        events = events.where((event) {
          return event.title.toLowerCase().contains(
                query.titleKeyword!.toLowerCase(),
              );
        }).toList();
      }

      // 如果包含已完成事件，合并已完成事件
      if (query.includeCompleted == true) {
        final completedEvents = await _parseCompletedEvents(data);
        events = [...events, ...completedEvents];
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          events,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(events);
    } catch (e) {
      return Result.failure('搜索事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 已完成事件操作实现 ============

  @override
  Future<Result<List<CalendarEventDto>>> getCompletedEvents(
      {PaginationParams? pagination}) async {
    try {
      final data = await _readAllEvents();
      var completedEvents = await _parseCompletedEvents(data);

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          completedEvents,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(completedEvents);
    } catch (e) {
      return Result.failure('获取已完成事件列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto?>> getCompletedEventById(String id) async {
    try {
      final data = await _readAllEvents();
      final completedEvents = await _parseCompletedEvents(data);
      final event = completedEvents.where((e) => e.id == id).firstOrNull;
      return Result.success(event);
    } catch (e) {
      return Result.failure('获取已完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CalendarEventDto>> restoreCompletedEvent(String id) async {
    try {
      final data = await _readAllEvents();
      final completedEvents = await _parseCompletedEvents(data);
      final index = completedEvents.indexWhere((e) => e.id == id);

      if (index == -1) {
        return Result.failure('已完成事件不存在', code: ErrorCodes.notFound);
      }

      final events = await _parseEvents(data);

      final completedEvent = completedEvents[index];
      final restoredEvent = completedEvent.copyWith(
        completedTime: null,
        updatedAt: DateTime.now(),
      );

      completedEvents.removeAt(index);
      events.add(restoredEvent);

      await _saveAllEvents({
        'events': events.map((e) => e.toJson()).toList(),
        'completedEvents': completedEvents.map((e) => e.toJson()).toList(),
      });

      return Result.success(restoredEvent);
    } catch (e) {
      return Result.failure('恢复事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteCompletedEvent(String id) async {
    try {
      final data = await _readAllEvents();
      final completedEvents = await _parseCompletedEvents(data);
      final initialLength = completedEvents.length;
      completedEvents.removeWhere((e) => e.id == id);

      if (completedEvents.length == initialLength) {
        return Result.failure('已完成事件不存在', code: ErrorCodes.notFound);
      }

      await _saveAllEvents({
        'events': (data?['events'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        'completedEvents': completedEvents.map((e) => e.toJson()).toList(),
      });

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除已完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }
}
