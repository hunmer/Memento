part of 'activity_plugin.dart';

// 以下函数供 ActivityPlugin.defineJSAPI() 使用

// ==================== JS API 实现 ====================

/// 获取指定日期的活动列表
/// 参数: params - { date?: string, offset?: number, count?: number } (YYYY-MM-DD 格式, 默认今天)
/// 支持分页参数: offset, count
Future<String> _jsGetActivities(Map<String, dynamic> params) async {
  try {
    final result = await ActivityPlugin.instance._activityUseCase.getActivities(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取活动失败: $e'});
  }
}

/// 创建活动
/// 参数: params - {
///   startTime: string (必需, ISO 8601 格式),
///   endTime: string (必需, ISO 8601 格式),
///   title: string (必需),
///   id: string (可选, 自定义ID),
///   tags?: Array 或 string,
///   description?: string,
///   mood?: string
/// }
Future<String> _jsCreateActivity(Map<String, dynamic> params) async {
  try {
    final result = await ActivityPlugin.instance._activityUseCase.createActivity(params);

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    return jsonEncode({
      'success': true,
      'activity': result.dataOrNull,
    });
  } catch (e) {
    return jsonEncode({'success': false, 'error': '创建活动失败: $e'});
  }
}

/// 更新活动
/// 参数: params - {
///   activityId: string (必需),
///   date: string (必需, YYYY-MM-DD 格式),
///   startTime: string (必需, ISO 8601 格式),
///   endTime: string (必需, ISO 8601 格式),
///   title: string (必需),
///   tags?: List or string,
///   description?: string,
///   mood?: string
/// }
Future<String> _jsUpdateActivity(Map<String, dynamic> params) async {
  try {
    // 转换参数格式：activityId -> id
    final updatedParams = Map<String, dynamic>.from(params);
    if (updatedParams.containsKey('activityId')) {
      updatedParams['id'] = updatedParams.remove('activityId');
    }

    // 如果没有 date，从 startTime 推断
    if (!updatedParams.containsKey('date') && updatedParams.containsKey('startTime')) {
      final startTimeStr = updatedParams['startTime'] as String;
      final startTime = DateTime.parse(startTimeStr);
      updatedParams['date'] =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
    }

    final result = await ActivityPlugin.instance._activityUseCase.updateActivity(updatedParams);

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    return jsonEncode({
      'success': true,
      'activity': result.dataOrNull,
    });
  } catch (e) {
    return jsonEncode({'success': false, 'error': '更新活动失败: $e'});
  }
}

/// 删除活动
/// 参数: params - {
///   activityId: string (必需),
///   date: string (必需, YYYY-MM-DD 格式)
/// }
Future<String> _jsDeleteActivity(Map<String, dynamic> params) async {
  try {
    // 转换参数格式：activityId -> id
    final updatedParams = Map<String, dynamic>.from(params);
    if (updatedParams.containsKey('activityId')) {
      updatedParams['id'] = updatedParams.remove('activityId');
    }

    final result = await ActivityPlugin.instance._activityUseCase.deleteActivity(updatedParams);

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    return jsonEncode({'success': true});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '删除活动失败: $e'});
  }
}

/// 获取今日统计
/// 参数: params - {} (无需参数)
/// 返回: { activityCount, durationMinutes, durationHours, remainingMinutes, remainingHours }
Future<String> _jsGetTodayStats(Map<String, dynamic> params) async {
  try {
    final result = await ActivityPlugin.instance._activityUseCase.getTodayStats(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final statsMap = result.dataOrNull as Map<String, dynamic>;
    return jsonEncode({
      'activityCount': statsMap['activityCount'],
      'durationMinutes': statsMap['durationMinutes'],
      'durationHours': statsMap['durationHours'].toString(),
      'remainingMinutes': statsMap['remainingMinutes'],
      'remainingHours': (statsMap['remainingMinutes'] / 60).toStringAsFixed(1),
    });
  } catch (e) {
    return jsonEncode({'error': '获取统计失败: $e'});
  }
}

/// 获取标签分组
/// 参数: params - {} (无需参数)
Future<String> _jsGetTagGroups(Map<String, dynamic> params) async {
  try {
    final result = await ActivityPlugin.instance._activityUseCase.getTagGroups(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final tagGroups = result.dataOrNull as List<dynamic>;
    return jsonEncode(
      tagGroups.map((g) => {'name': g['name'], 'tags': g['tags']}).toList(),
    );
  } catch (e) {
    return jsonEncode({'error': '获取标签分组失败: $e'});
  }
}

/// 获取最近使用的标签
/// 参数: params - {} (无需参数)
Future<String> _jsGetRecentTags(Map<String, dynamic> params) async {
  try {
    final result = await ActivityPlugin.instance._activityUseCase.getRecentTags(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取最近标签失败: $e'});
  }
}

// ==================== 通知相关 API ====================

/// 启用活动通知
/// 参数: params - {} (无需参数)
Future<String> _jsEnableNotification(Map<String, dynamic> params) async {
  try {
    if (!UniversalPlatform.isAndroid) {
      return jsonEncode({'success': false, 'error': '仅支持Android平台'});
    }

    await ActivityPlugin.instance._notificationService.enable();
    return jsonEncode({'success': true, 'message': '活动通知已启用'});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '启用通知失败: $e'});
  }
}

/// 禁用活动通知
/// 参数: params - {} (无需参数)
Future<String> _jsDisableNotification(Map<String, dynamic> params) async {
  try {
    await ActivityPlugin.instance._notificationService.disable();
    return jsonEncode({'success': true, 'message': '活动通知已禁用'});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '禁用通知失败: $e'});
  }
}

/// 获取通知状态
/// 参数: params - {} (无需参数)
Future<String> _jsGetNotificationStatus(Map<String, dynamic> params) async {
  try {
    final stats = ActivityPlugin.instance._notificationService.getStats();
    return jsonEncode({'success': true, 'status': stats});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '获取通知状态失败: $e'});
  }
}
