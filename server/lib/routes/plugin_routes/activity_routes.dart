import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Activity 插件 HTTP 路由
class ActivityRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  ActivityRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 活动 API ====================
    // GET /activities - 获取活动列表
    router.get('/activities', _getActivities);

    // POST /activities - 创建活动
    router.post('/activities', _createActivity);

    // PUT /activities/<id> - 更新活动
    router.put('/activities/<id>', _updateActivity);

    // DELETE /activities/<id> - 删除活动
    router.delete('/activities/<id>', _deleteActivity);

    // ==================== 统计 API ====================
    // GET /stats/today - 获取今日统计
    router.get('/stats/today', _getTodayStats);

    // GET /stats/range - 获取日期范围统计
    router.get('/stats/range', _getRangeStats);

    // ==================== 标签 API ====================
    // GET /tags - 获取标签分组
    router.get('/tags', _getTagGroups);

    // GET /tags/recent - 获取最近标签
    router.get('/tags/recent', _getRecentTags);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _successResponse(dynamic data) {
    return Response.ok(
      jsonEncode({
        'success': true,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _paginatedResponse(
    List<dynamic> data, {
    int offset = 0,
    int count = 100,
  }) {
    final paginated = _dataService.paginate(data, offset: offset, count: count);
    return Response.ok(
      jsonEncode({
        'success': true,
        ...paginated,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 格式化日期为文件名格式
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 读取指定日期的活动
  Future<List<Map<String, dynamic>>> _readActivitiesForDate(
    String userId,
    String dateStr,
  ) async {
    final data = await _dataService.readPluginData(
      userId,
      'activity',
      'activities_$dateStr.json',
    );
    if (data == null) return [];

    // activities 文件结构: { "activities": [...] }
    final activities = data['activities'] as List<dynamic>? ?? [];
    return activities.cast<Map<String, dynamic>>();
  }

  /// 保存指定日期的活动
  Future<void> _saveActivitiesForDate(
    String userId,
    String dateStr,
    List<Map<String, dynamic>> activities,
  ) async {
    await _dataService.writePluginData(
      userId,
      'activity',
      'activities_$dateStr.json',
      {'activities': activities},
    );
  }

  // ==================== 活动处理方法 ====================

  /// 获取活动列表
  Future<Response> _getActivities(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final dateParam = request.url.queryParameters['date'];

    try {
      final dateStr = dateParam ?? _formatDate(DateTime.now());
      final activities = await _readActivitiesForDate(userId, dateStr);

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(activities, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(activities);
    } catch (e) {
      return _errorResponse(500, '获取活动失败: $e');
    }
  }

  /// 创建活动
  Future<Response> _createActivity(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 验证必需参数
      final startTimeStr = data['startTime'] as String?;
      final endTimeStr = data['endTime'] as String?;
      final title = data['title'] as String?;

      if (startTimeStr == null || endTimeStr == null || title == null) {
        return _errorResponse(400, '缺少必需参数: startTime, endTime, title');
      }

      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);
      final dateStr = _formatDate(startTime);

      final activityId = data['id'] as String? ?? _uuid.v4();

      final activity = {
        'id': activityId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'title': title,
        'tags': data['tags'] ?? <String>[],
        'description': data['description'],
        'mood': data['mood'],
        'metadata': data['metadata'],
      };

      // 读取现有活动
      final activities = await _readActivitiesForDate(userId, dateStr);

      // 检查时间重叠
      for (final existing in activities) {
        final existingStart = DateTime.parse(existing['startTime'] as String);
        final existingEnd = DateTime.parse(existing['endTime'] as String);
        if (startTime.isBefore(existingEnd) && endTime.isAfter(existingStart)) {
          // 有重叠，替换现有活动
          activities.removeWhere((a) => a['id'] == existing['id']);
          break;
        }
      }

      activities.add(activity);

      // 按开始时间排序
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['startTime'] as String);
        final bTime = DateTime.parse(b['startTime'] as String);
        return aTime.compareTo(bTime);
      });

      await _saveActivitiesForDate(userId, dateStr, activities);

      return _successResponse(activity);
    } catch (e) {
      return _errorResponse(500, '创建活动失败: $e');
    }
  }

  /// 更新活动
  Future<Response> _updateActivity(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 获取活动所在日期
      final dateParam = data['date'] as String? ??
          request.url.queryParameters['date'] ??
          _formatDate(DateTime.now());

      final activities = await _readActivitiesForDate(userId, dateParam);
      final index = activities.indexWhere((a) => a['id'] == id);

      if (index == -1) {
        return _errorResponse(404, '活动不存在');
      }

      // 合并更新
      final activity = Map<String, dynamic>.from(activities[index]);
      if (data.containsKey('startTime')) activity['startTime'] = data['startTime'];
      if (data.containsKey('endTime')) activity['endTime'] = data['endTime'];
      if (data.containsKey('title')) activity['title'] = data['title'];
      if (data.containsKey('tags')) activity['tags'] = data['tags'];
      if (data.containsKey('description')) activity['description'] = data['description'];
      if (data.containsKey('mood')) activity['mood'] = data['mood'];
      if (data.containsKey('metadata')) activity['metadata'] = data['metadata'];

      activities[index] = activity;

      // 按开始时间排序
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['startTime'] as String);
        final bTime = DateTime.parse(b['startTime'] as String);
        return aTime.compareTo(bTime);
      });

      await _saveActivitiesForDate(userId, dateParam, activities);

      return _successResponse(activity);
    } catch (e) {
      return _errorResponse(500, '更新活动失败: $e');
    }
  }

  /// 删除活动
  Future<Response> _deleteActivity(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final dateParam = request.url.queryParameters['date'] ??
        _formatDate(DateTime.now());

    try {
      final activities = await _readActivitiesForDate(userId, dateParam);
      final initialLength = activities.length;

      activities.removeWhere((a) => a['id'] == id);

      if (activities.length == initialLength) {
        return _errorResponse(404, '活动不存在');
      }

      await _saveActivitiesForDate(userId, dateParam, activities);

      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除活动失败: $e');
    }
  }

  // ==================== 统计处理方法 ====================

  /// 获取今日统计
  Future<Response> _getTodayStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final dateStr = _formatDate(DateTime.now());
      final activities = await _readActivitiesForDate(userId, dateStr);

      // 计算总时长
      var totalMinutes = 0;
      for (final activity in activities) {
        final startTime = DateTime.parse(activity['startTime'] as String);
        final endTime = DateTime.parse(activity['endTime'] as String);
        totalMinutes += endTime.difference(startTime).inMinutes;
      }

      final stats = {
        'date': dateStr,
        'activityCount': activities.length,
        'durationMinutes': totalMinutes,
        'durationHours': totalMinutes ~/ 60,
        'remainingMinutes': totalMinutes % 60,
      };

      return _successResponse(stats);
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }

  /// 获取日期范围统计
  Future<Response> _getRangeStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final startDateParam = request.url.queryParameters['startDate'];
    final endDateParam = request.url.queryParameters['endDate'];

    if (startDateParam == null || endDateParam == null) {
      return _errorResponse(400, '缺少参数: startDate, endDate');
    }

    try {
      final startDate = DateTime.parse(startDateParam);
      final endDate = DateTime.parse(endDateParam);

      var totalActivities = 0;
      var totalMinutes = 0;
      final dailyStats = <Map<String, dynamic>>[];

      // 遍历日期范围
      var current = startDate;
      while (!current.isAfter(endDate)) {
        final dateStr = _formatDate(current);
        final activities = await _readActivitiesForDate(userId, dateStr);

        var dayMinutes = 0;
        for (final activity in activities) {
          final start = DateTime.parse(activity['startTime'] as String);
          final end = DateTime.parse(activity['endTime'] as String);
          dayMinutes += end.difference(start).inMinutes;
        }

        dailyStats.add({
          'date': dateStr,
          'activityCount': activities.length,
          'durationMinutes': dayMinutes,
        });

        totalActivities += activities.length;
        totalMinutes += dayMinutes;

        current = current.add(const Duration(days: 1));
      }

      final stats = {
        'startDate': startDateParam,
        'endDate': endDateParam,
        'totalActivities': totalActivities,
        'totalMinutes': totalMinutes,
        'totalHours': totalMinutes ~/ 60,
        'dailyStats': dailyStats,
      };

      return _successResponse(stats);
    } catch (e) {
      return _errorResponse(500, '获取范围统计失败: $e');
    }
  }

  // ==================== 标签处理方法 ====================

  /// 获取标签分组
  Future<Response> _getTagGroups(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _dataService.readPluginData(
        userId,
        'activity',
        'tag_groups.json',
      );

      // tag_groups.json 是一个数组
      final tagGroups = data is List ? data : [];

      return _successResponse(tagGroups);
    } catch (e) {
      return _errorResponse(500, '获取标签分组失败: $e');
    }
  }

  /// 获取最近标签
  Future<Response> _getRecentTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _dataService.readPluginData(
        userId,
        'activity',
        'recent_tags.json',
      );

      // recent_tags.json 是一个字符串数组
      final recentTags = data is List ? data : [];

      return _successResponse(recentTags);
    } catch (e) {
      return _errorResponse(500, '获取最近标签失败: $e');
    }
  }
}
