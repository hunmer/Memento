part of 'calendar_plugin.dart';

// ==================== JS API 定义 ====================

@override
Map<String, Function> defineJSAPI() {
  return {
    // 事件查询
    'getEvents': _jsGetEvents,
    'getTodayEvents': _jsGetTodayEvents,
    'getEventsByDateRange': _jsGetEventsByDateRange,
    'getUpcoming': _jsGetUpcoming,

    // 事件操作
    'createEvent': _jsCreateEvent,
    'updateEvent': _jsUpdateEvent,
    'deleteEvent': _jsDeleteEvent,
    'completeEvent': _jsCompleteEvent,

    // 已完成事件
    'getCompletedEvents': _jsGetCompletedEvents,

    // 事件查找方法
    'findEventBy': _jsFindEventBy,
    'findEventById': _jsFindEventById,
    'findEventByTitle': _jsFindEventByTitle,
  };
}

// ==================== 分页控制器 ====================

/// 分页控制器 - 对列表进行分页处理
/// @param list 原始数据列表
/// @param offset 起始位置（默认 0）
/// @param count 返回数量（默认 100）
/// @return 分页后的数据，包含 data、total、offset、count、hasMore
Map<String, dynamic> _paginate<T>(
  List<T> list, {
  int offset = 0,
  int count = 100,
}) {
  final total = list.length;
  final start = offset.clamp(0, total);
  final end = (start + count).clamp(start, total);
  final data = list.sublist(start, end);

  return {
    'data': data,
    'total': total,
    'offset': start,
    'count': data.length,
    'hasMore': end < total,
  };
}

// ==================== JS API 实现 ====================

/// 获取所有事件（包括 Todo 任务事件）
/// 支持分页参数: offset, count
Future<String> _jsGetEvents(Map<String, dynamic> params) async {
  final result = await calendarUseCase.getEvents(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 获取今日事件
/// 支持分页参数: offset, count
Future<String> _jsGetTodayEvents(Map<String, dynamic> params) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  // 添加日期过滤参数
  final filteredParams = Map<String, dynamic>.from(params);
  filteredParams['startDate'] = today.subtract(const Duration(seconds: 1));
  filteredParams['endDate'] = tomorrow;

  final result = await calendarUseCase.searchEvents(filteredParams);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 根据日期范围获取事件
/// 支持分页参数: offset, count
Future<String> _jsGetEventsByDateRange(Map<String, dynamic> params) async {
  // 提取必需参数并验证
  final String? startDateStr = params['startDate'];
  if (startDateStr == null || startDateStr.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: startDate'});
  }

  final String? endDateStr = params['endDate'];
  if (endDateStr == null || endDateStr.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: endDate'});
  }

  final startDate = DateTime.parse(startDateStr);
  final endDate = DateTime.parse(endDateStr);

  // 添加日期过滤参数
  final filteredParams = Map<String, dynamic>.from(params);
  filteredParams['startDate'] = startDate;
  filteredParams['endDate'] = endDate;

  final result = await calendarUseCase.searchEvents(filteredParams);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 获取即将到来的事件
/// @param params.days - 天数范围（可选，默认7天）
/// @param params.offset - 分页起始位置（可选）
/// @param params.count - 分页返回数量（可选，默认100）
Future<String> _jsGetUpcoming(Map<String, dynamic> params) async {
  try {
    final int days = params['days'] ?? 7;
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    final filteredParams = Map<String, dynamic>.from(params);
    filteredParams['startDate'] = now;
    filteredParams['endDate'] = endDate;

    final result = await calendarUseCase.searchEvents(filteredParams);

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return jsonEncode({
      'success': true,
      'data': result.dataOrNull ?? [],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    return jsonEncode({
      'success': false,
      'error': '获取即将到来的事件失败: $e',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

/// 创建事件
Future<String> _jsCreateEvent(Map<String, dynamic> params) async {
  final result = await calendarUseCase.createEvent(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 更新事件
Future<String> _jsUpdateEvent(Map<String, dynamic> params) async {
  final result = await calendarUseCase.updateEvent(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 删除事件
Future<String> _jsDeleteEvent(Map<String, dynamic> params) async {
  final result = await calendarUseCase.deleteEvent(params);

  if (result.isFailure) {
    return jsonEncode({
      'success': false,
      'error': result.errorOrNull?.message,
    });
  }

  return jsonEncode({'success': true});
}

/// 完成事件
Future<String> _jsCompleteEvent(Map<String, dynamic> params) async {
  final result = await calendarUseCase.completeEvent(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 获取已完成事件
/// 支持分页参数: offset, count
Future<String> _jsGetCompletedEvents(Map<String, dynamic> params) async {
  final result = await calendarUseCase.getCompletedEvents(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

// ==================== 事件查找方法 ====================

/// 通用事件查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindEventBy(Map<String, dynamic> params) async {
  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: field'});
  }

  final dynamic value = params['value'];
  if (value == null) {
    return jsonEncode({'error': '缺少必需参数: value'});
  }

  // 这里需要特殊处理，因为 UseCase 的 searchEvents 主要用于日期范围搜索
  // 对于字段查找，我们仍然使用原有的逻辑
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final events = controller.getAllEvents();
  final List<CalendarEvent> matchedEvents = [];

  for (final event in events) {
    final eventJson = event.toJson();

    // 检查字段是否匹配
    if (eventJson.containsKey(field) && eventJson[field] == value) {
      matchedEvents.add(event);
      if (!findAll) break; // 只找第一个
    }
  }

  if (findAll) {
    final eventsJson = matchedEvents.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(eventsJson);
  } else {
    if (matchedEvents.isEmpty) {
      return jsonEncode(null);
    }
    return jsonEncode(matchedEvents.first.toJson());
  }
}

/// 根据ID查找事件
/// @param params.id 事件ID (必需)
Future<String> _jsFindEventById(Map<String, dynamic> params) async {
  final result = await calendarUseCase.getEventById(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 根据标题查找事件
/// @param params.title 事件标题 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindEventByTitle(Map<String, dynamic> params) async {
  final String? title = params['title'];
  if (title == null || title.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: title'});
  }

  // 这里需要特殊处理，因为 UseCase 的 searchEvents 主要用于日期范围搜索
  // 对于标题查找，我们仍然使用原有的逻辑
  final bool fuzzy = params['fuzzy'] ?? false;
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final events = controller.getAllEvents();
  final List<CalendarEvent> matchedEvents = [];

  for (final event in events) {
    bool matches = false;
    if (fuzzy) {
      matches = event.title.contains(title);
    } else {
      matches = event.title == title;
    }

    if (matches) {
      matchedEvents.add(event);
      if (!findAll) break;
    }
  }

  if (findAll) {
    final eventsJson = matchedEvents.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(eventsJson);
  } else {
    if (matchedEvents.isEmpty) {
      return jsonEncode(null);
    }
    return jsonEncode(matchedEvents.first.toJson());
  }
}
