import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Todo 插件 HTTP 路由
class TodoRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  TodoRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 任务 API ====================
    router.get('/tasks', _getTasks);
    router.get('/tasks/<id>', _getTask);
    router.post('/tasks', _createTask);
    router.put('/tasks/<id>', _updateTask);
    router.delete('/tasks/<id>', _deleteTask);

    // ==================== 任务操作 API ====================
    router.post('/tasks/<id>/complete', _completeTask);
    router.post('/tasks/<id>/uncomplete', _uncompleteTask);

    // ==================== 筛选/搜索 API ====================
    router.get('/tasks/filter/today', _getTodayTasks);
    router.get('/tasks/filter/overdue', _getOverdueTasks);
    router.get('/tasks/filter/completed', _getCompletedTasks);
    router.get('/tasks/filter/pending', _getPendingTasks);
    router.get('/search', _searchTasks);

    // ==================== 统计 API ====================
    router.get('/stats', _getStats);

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

  Response _paginatedResponse(List<dynamic> data, {int offset = 0, int count = 100}) {
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

  /// 读取所有任务
  Future<List<Map<String, dynamic>>> _readTasks(String userId) async {
    final data = await _dataService.readPluginData(userId, 'todo', 'tasks.json');
    if (data == null) return [];
    final tasks = data['tasks'] as List<dynamic>? ?? [];
    return tasks.cast<Map<String, dynamic>>();
  }

  /// 保存所有任务
  Future<void> _saveTasks(String userId, List<Map<String, dynamic>> tasks) async {
    await _dataService.writePluginData(userId, 'todo', 'tasks.json', {'tasks': tasks});
  }

  /// 格式化日期为 YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 解析日期字符串
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// 检查任务是否过期
  bool _isOverdue(Map<String, dynamic> task) {
    if (task['completed'] == true) return false;
    final dueDateStr = task['dueDate'] as String?;
    if (dueDateStr == null) return false;
    final dueDate = _parseDate(dueDateStr);
    if (dueDate == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return dueDate.isBefore(todayDate);
  }

  /// 检查任务是否是今日任务
  bool _isToday(Map<String, dynamic> task) {
    final dueDateStr = task['dueDate'] as String?;
    if (dueDateStr == null) return false;
    final dueDate = _parseDate(dueDateStr);
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate.year == today.year &&
           dueDate.month == today.month &&
           dueDate.day == today.day;
  }

  // ==================== 任务处理方法 ====================

  Future<Response> _getTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      var tasks = await _readTasks(userId);

      // 可选筛选参数
      final completed = request.url.queryParameters['completed'];
      final priority = request.url.queryParameters['priority'];
      final category = request.url.queryParameters['category'];

      if (completed != null) {
        final isCompleted = completed.toLowerCase() == 'true';
        tasks = tasks.where((t) => (t['completed'] == true) == isCompleted).toList();
      }

      if (priority != null) {
        final priorityLevel = int.tryParse(priority);
        if (priorityLevel != null) {
          tasks = tasks.where((t) => t['priority'] == priorityLevel).toList();
        }
      }

      if (category != null) {
        tasks = tasks.where((t) => t['category'] == category).toList();
      }

      // 排序：未完成优先，然后按优先级降序，最后按创建时间降序
      tasks.sort((a, b) {
        // 完成状态
        final aCompleted = a['completed'] == true ? 1 : 0;
        final bCompleted = b['completed'] == true ? 1 : 0;
        if (aCompleted != bCompleted) return aCompleted - bCompleted;

        // 优先级（高优先级在前）
        final aPriority = a['priority'] as int? ?? 0;
        final bPriority = b['priority'] as int? ?? 0;
        if (aPriority != bPriority) return bPriority - aPriority;

        // 创建时间（新的在前）
        final aCreated = a['createdAt'] as String? ?? '';
        final bCreated = b['createdAt'] as String? ?? '';
        return bCreated.compareTo(aCreated);
      });

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(tasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(tasks);
    } catch (e) {
      return _errorResponse(500, '获取任务失败: $e');
    }
  }

  Future<Response> _getTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final task = tasks.firstWhere((t) => t['id'] == id, orElse: () => <String, dynamic>{});
      if (task.isEmpty) return _errorResponse(404, '任务不存在');
      return _successResponse(task);
    } catch (e) {
      return _errorResponse(500, '获取任务失败: $e');
    }
  }

  Future<Response> _createTask(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final title = data['title'] as String?;
      if (title == null || title.isEmpty) {
        return _errorResponse(400, '缺少必需参数: title');
      }

      final taskId = data['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final task = {
        'id': taskId,
        'title': title,
        'description': data['description'],
        'completed': data['completed'] ?? false,
        'completedAt': null,
        'dueDate': data['dueDate'],
        'dueTime': data['dueTime'],
        'priority': data['priority'] ?? 0,  // 0: 无, 1: 低, 2: 中, 3: 高
        'category': data['category'],
        'tags': data['tags'] ?? <String>[],
        'subtasks': data['subtasks'] ?? <Map<String, dynamic>>[],
        'reminder': data['reminder'],
        'repeat': data['repeat'],
        'notes': data['notes'],
        'createdAt': now,
        'updatedAt': now,
      };

      final tasks = await _readTasks(userId);
      tasks.add(task);
      await _saveTasks(userId, tasks);

      return _successResponse(task);
    } catch (e) {
      return _errorResponse(500, '创建任务失败: $e');
    }
  }

  Future<Response> _updateTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final index = tasks.indexWhere((t) => t['id'] == id);
      if (index == -1) return _errorResponse(404, '任务不存在');

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      final task = Map<String, dynamic>.from(tasks[index]);

      // 更新可修改字段
      if (updates.containsKey('title')) task['title'] = updates['title'];
      if (updates.containsKey('description')) task['description'] = updates['description'];
      if (updates.containsKey('completed')) {
        final wasCompleted = task['completed'] == true;
        final nowCompleted = updates['completed'] == true;
        task['completed'] = nowCompleted;
        if (!wasCompleted && nowCompleted) {
          task['completedAt'] = DateTime.now().toIso8601String();
        } else if (wasCompleted && !nowCompleted) {
          task['completedAt'] = null;
        }
      }
      if (updates.containsKey('dueDate')) task['dueDate'] = updates['dueDate'];
      if (updates.containsKey('dueTime')) task['dueTime'] = updates['dueTime'];
      if (updates.containsKey('priority')) task['priority'] = updates['priority'];
      if (updates.containsKey('category')) task['category'] = updates['category'];
      if (updates.containsKey('tags')) task['tags'] = updates['tags'];
      if (updates.containsKey('subtasks')) task['subtasks'] = updates['subtasks'];
      if (updates.containsKey('reminder')) task['reminder'] = updates['reminder'];
      if (updates.containsKey('repeat')) task['repeat'] = updates['repeat'];
      if (updates.containsKey('notes')) task['notes'] = updates['notes'];
      task['updatedAt'] = DateTime.now().toIso8601String();

      tasks[index] = task;
      await _saveTasks(userId, tasks);
      return _successResponse(task);
    } catch (e) {
      return _errorResponse(500, '更新任务失败: $e');
    }
  }

  Future<Response> _deleteTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final initialLength = tasks.length;
      tasks.removeWhere((t) => t['id'] == id);
      if (tasks.length == initialLength) return _errorResponse(404, '任务不存在');

      await _saveTasks(userId, tasks);
      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除任务失败: $e');
    }
  }

  // ==================== 任务操作方法 ====================

  Future<Response> _completeTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final index = tasks.indexWhere((t) => t['id'] == id);
      if (index == -1) return _errorResponse(404, '任务不存在');

      final task = Map<String, dynamic>.from(tasks[index]);
      if (task['completed'] == true) {
        return _errorResponse(400, '任务已完成');
      }

      task['completed'] = true;
      task['completedAt'] = DateTime.now().toIso8601String();
      task['updatedAt'] = DateTime.now().toIso8601String();

      tasks[index] = task;
      await _saveTasks(userId, tasks);
      return _successResponse(task);
    } catch (e) {
      return _errorResponse(500, '完成任务失败: $e');
    }
  }

  Future<Response> _uncompleteTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final index = tasks.indexWhere((t) => t['id'] == id);
      if (index == -1) return _errorResponse(404, '任务不存在');

      final task = Map<String, dynamic>.from(tasks[index]);
      if (task['completed'] != true) {
        return _errorResponse(400, '任务未完成');
      }

      task['completed'] = false;
      task['completedAt'] = null;
      task['updatedAt'] = DateTime.now().toIso8601String();

      tasks[index] = task;
      await _saveTasks(userId, tasks);
      return _successResponse(task);
    } catch (e) {
      return _errorResponse(500, '取消完成失败: $e');
    }
  }

  // ==================== 筛选方法 ====================

  Future<Response> _getTodayTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final todayTasks = tasks.where(_isToday).toList();

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(todayTasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(todayTasks);
    } catch (e) {
      return _errorResponse(500, '获取今日任务失败: $e');
    }
  }

  Future<Response> _getOverdueTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final overdueTasks = tasks.where(_isOverdue).toList();

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(overdueTasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(overdueTasks);
    } catch (e) {
      return _errorResponse(500, '获取过期任务失败: $e');
    }
  }

  Future<Response> _getCompletedTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final completedTasks = tasks.where((t) => t['completed'] == true).toList();

      // 按完成时间降序排序
      completedTasks.sort((a, b) {
        final aTime = a['completedAt'] as String? ?? '';
        final bTime = b['completedAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(completedTasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(completedTasks);
    } catch (e) {
      return _errorResponse(500, '获取已完成任务失败: $e');
    }
  }

  Future<Response> _getPendingTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);
      final pendingTasks = tasks.where((t) => t['completed'] != true).toList();

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(pendingTasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(pendingTasks);
    } catch (e) {
      return _errorResponse(500, '获取待办任务失败: $e');
    }
  }

  Future<Response> _searchTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final keyword = request.url.queryParameters['keyword'];

    try {
      var tasks = await _readTasks(userId);

      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        tasks = tasks.where((task) {
          final title = (task['title'] as String? ?? '').toLowerCase();
          final desc = (task['description'] as String? ?? '').toLowerCase();
          final notes = (task['notes'] as String? ?? '').toLowerCase();
          final tags = (task['tags'] as List<dynamic>? ?? [])
              .map((t) => t.toString().toLowerCase())
              .toList();
          return title.contains(lowerKeyword) ||
              desc.contains(lowerKeyword) ||
              notes.contains(lowerKeyword) ||
              tags.any((t) => t.contains(lowerKeyword));
        }).toList();
      }

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(tasks, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(tasks);
    } catch (e) {
      return _errorResponse(500, '搜索任务失败: $e');
    }
  }

  // ==================== 统计方法 ====================

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final tasks = await _readTasks(userId);

      final total = tasks.length;
      final completed = tasks.where((t) => t['completed'] == true).length;
      final pending = total - completed;
      final overdue = tasks.where(_isOverdue).length;
      final today = tasks.where(_isToday).length;
      final todayCompleted = tasks.where((t) => _isToday(t) && t['completed'] == true).length;

      // 按优先级统计
      final byPriority = <int, int>{};
      for (final task in tasks.where((t) => t['completed'] != true)) {
        final priority = task['priority'] as int? ?? 0;
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      // 按分类统计
      final byCategory = <String, int>{};
      for (final task in tasks) {
        final category = task['category'] as String? ?? '未分类';
        byCategory[category] = (byCategory[category] ?? 0) + 1;
      }

      return _successResponse({
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
        'today': today,
        'todayCompleted': todayCompleted,
        'completionRate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
        'byPriority': {
          'none': byPriority[0] ?? 0,
          'low': byPriority[1] ?? 0,
          'medium': byPriority[2] ?? 0,
          'high': byPriority[3] ?? 0,
        },
        'byCategory': byCategory,
      });
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }
}
