part of 'checkin_plugin.dart';

// ==================== JS API 定义 ====================

@override
Map<String, Function> defineJSAPI() {
  return {
    // 获取签到项目列表
    'getCheckinItems': _jsGetCheckinItems,

    // 执行签到
    'checkin': _jsCheckin,

    // 获取签到历史
    'getCheckinHistory': _jsGetCheckinHistory,

    // 获取统计信息
    'getStats': _jsGetStats,

    // 创建签到项目
    'createCheckinItem': _jsCreateCheckinItem,
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

/// 获取签到项目列表
/// 支持分页参数: offset, count
Future<String> _jsGetCheckinItems(Map<String, dynamic> params) async {
  try {
    // 使用 UseCase 获取数据
    final result = await _checkinUseCase.getItems(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    final jsonDataList = result.dataOrNull as List<dynamic>;
    final items = jsonDataList
        .map((json) => CheckinItemDto.fromJson(json as Map<String, dynamic>))
        .toList();

    // 转换为前端需要的格式
    final jsonList = items.map((dto) {
      final item = _dtoToCheckinItem(dto);
      return {
        'id': item.id,
        'name': item.name,
        'group': item.group,
        'description': item.description,
        'icon': item.icon.codePoint,
        'color': '0x${item.color.value.toRadixString(16).padLeft(8, '0')}',
        'frequency': item.frequency,
        'consecutiveDays': item.getConsecutiveDays(),
        'isCheckedToday': item.isCheckedToday(),
        'lastCheckinDate': item.lastCheckinDate?.toIso8601String(),
      };
    }).toList();

    // UseCase 已经处理了分页，直接返回
    return jsonEncode({
      'success': true,
      'data': jsonList,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    return jsonEncode({'error': '获取签到项目失败: $e'});
  }
}

/// 执行签到
Future<String> _jsCheckin(Map<String, dynamic> params) async {
  try {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    // 可选参数
    final String? note = params['note'];

    // 创建签到记录
    final now = DateTime.now();
    final record = {
      'startTime': now.toIso8601String(),
      'endTime': now.toIso8601String(),
      'checkinTime': now.toIso8601String(),
      'note': note,
    };

    // 使用 UseCase 添加打卡记录
    final result = await _checkinUseCase.addCheckinRecord({
      'itemId': itemId,
      ...record,
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    // 更新本地列表
    await _saveCheckinItems();

    // 查找对应的项目以获取连续天数
    final item = _checkinItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('签到项目不存在'),
    );

    final responseData = {
      'message': '签到成功',
      'consecutiveDays': item.getConsecutiveDays(),
      'checkinTime': now.toIso8601String(),
    };

    return jsonEncode({
      'success': true,
      'data': responseData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    return jsonEncode({'error': '签到失败: $e'});
  }
}

/// 获取签到历史
Future<String> _jsGetCheckinHistory(Map<String, dynamic> params) async {
  try {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    // 获取项目信息
    final itemResult = await _checkinUseCase.getItemById({'id': itemId});
    if (itemResult.isFailure || itemResult.dataOrNull == null) {
      return jsonEncode({'error': '签到项目不存在: $itemId'});
    }

    final json = itemResult.dataOrNull as Map<String, dynamic>;
    final itemDto = CheckinItemDto.fromJson(json);
    final item = _dtoToCheckinItem(itemDto);

    // 可选参数
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];

    // 解析日期范围
    DateTime? start;
    DateTime? end;
    if (startDate != null) {
      start = DateTime.parse(startDate);
    }
    if (endDate != null) {
      end = DateTime.parse(endDate);
    }

    // 收集符合日期范围的记录
    final List<Map<String, dynamic>> history = [];

    item.checkInRecords.forEach((dateStr, records) {
      final date = DateTime.parse(dateStr);

      // 检查是否在日期范围内
      if (start != null && date.isBefore(start)) return;
      if (end != null && date.isAfter(end)) return;

      for (final record in records) {
        history.add({
          'date': dateStr,
          'checkinTime': record.checkinTime.toIso8601String(),
          'startTime': record.startTime.toIso8601String(),
          'endTime': record.endTime.toIso8601String(),
          'note': record.note,
        });
      }
    });

    // 按签到时间倒序排序
    history.sort((a, b) => b['checkinTime'].compareTo(a['checkinTime']));

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        history,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode({
        'itemId': itemId,
        'itemName': item.name,
        'history': paginated['data'],
        'total': paginated['total'],
        'offset': paginated['offset'],
        'count': paginated['count'],
        'hasMore': paginated['hasMore'],
      });
    }

    return jsonEncode({
      'itemId': itemId,
      'itemName': item.name,
      'history': history,
      'totalCount': history.length,
    });
  } catch (e) {
    return jsonEncode({'error': '获取签到历史失败: $e'});
  }
}

/// 获取统计信息
Future<String> _jsGetStats(Map<String, dynamic> params) async {
  try {
    // 可选参数
    final String? itemId = params['itemId'];

    if (itemId != null) {
      // 获取单个项目的统计信息
      final itemResult = await _checkinUseCase.getItemById({'id': itemId});
      if (itemResult.isFailure || itemResult.dataOrNull == null) {
        return jsonEncode({'error': '签到项目不存在: $itemId'});
      }

      final json = itemResult.dataOrNull as Map<String, dynamic>;
      final itemDto = CheckinItemDto.fromJson(json);
      final item = _dtoToCheckinItem(itemDto);

      return jsonEncode({
        'itemId': itemId,
        'itemName': item.name,
        'totalCheckins': item.checkInRecords.values.fold<int>(
          0,
          (sum, records) => sum + records.length,
        ),
        'consecutiveDays': item.getConsecutiveDays(),
        'isCheckedToday': item.isCheckedToday(),
        'lastCheckinDate': item.lastCheckinDate?.toIso8601String(),
      });
    } else {
      // 使用 UseCase 获取全局统计信息
      final statsResult = await _checkinUseCase.getStats({});
      if (statsResult.isFailure) {
        return jsonEncode({'error': statsResult.errorOrNull?.message ?? '未知错误'});
      }

      final stats = statsResult.dataOrNull as CheckinStatsDto;

      return jsonEncode({
        'totalItems': stats.totalItems,
        'todayCheckins': stats.todayCheckins,
        'totalCheckins': stats.totalCheckins,
        'completionRate': stats.completionRate,
      });
    }
  } catch (e) {
    return jsonEncode({'error': '获取统计信息失败: $e'});
  }
}

/// 创建签到项目
Future<String> _jsCreateCheckinItem(Map<String, dynamic> params) async {
  try {
    // 必需参数验证
    final String? name = params['name'];
    if (name == null) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    // 可选参数
    final String? id = params['id'];
    final String? group = params['group'];
    final String? description = params['description'];
    final int? icon = params['icon'] ?? Icons.check_circle.codePoint;
    final int? color = params['color'] ?? Colors.blue.value;

    // 使用 UseCase 创建项目
    final result = await _checkinUseCase.createItem({
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'group': group ?? '默认分组',
      'description': description ?? '',
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    // 更新本地列表
    await _saveCheckinItems();

    final json = result.dataOrNull as Map<String, dynamic>;
    final itemDto = CheckinItemDto.fromJson(json);
    final item = _dtoToCheckinItem(itemDto);

    return jsonEncode({
      'success': true,
      'message': '创建成功',
      'item': {
        'id': item.id,
        'name': item.name,
        'group': item.group,
        'description': item.description,
      },
    });
  } catch (e) {
    return jsonEncode({'error': '创建签到项目失败: $e'});
  }
}
