import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_todo_repository.dart';

/// Todo 插件 HTTP 路由
class TodoRoutes {
  final PluginDataService _dataService;

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

  /// 创建 UseCase 实例
  TodoUseCase _createUseCase(String userId) {
    final repository = ServerTodoRepository(
      dataService: _dataService,
      userId: userId,
    );
    return TodoUseCase(repository);
  }

  /// 成功响应
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

  /// 错误响应（从 Result 对象）
  Response _errorResponseFromResult(Result result) {
    final error = result.errorOrNull!;
    int statusCode;
    switch (error.code) {
      case ErrorCodes.notFound:
        statusCode = 404;
        break;
      case ErrorCodes.invalidParams:
        statusCode = 400;
        break;
      case ErrorCodes.unauthorized:
        statusCode = 401;
        break;
      default:
        statusCode = 500;
    }

    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': error.message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 错误响应（通用）
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

  /// 从 Request 提取查询参数
  Map<String, dynamic> _extractQueryParams(Request request) {
    return Map<String, dynamic>.from(request.url.queryParameters);
  }

  // ==================== 任务处理方法 ====================

  Future<Response> _getTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换查询参数类型
      if (params.containsKey('completed')) {
        params['completed'] = params['completed'] == 'true';
      }
      if (params.containsKey('priority')) {
        params['priority'] = int.tryParse(params['priority'] as String);
      }
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.getTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取任务失败: $e');
    }
  }

  Future<Response> _getTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.getTaskById({'id': id});

      if (result.isSuccess) {
        final task = result.dataOrNull;
        if (task == null) {
          return _errorResponse(404, '任务不存在');
        }
        return _successResponse(task);
      }
      return _errorResponseFromResult(result);
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

      final useCase = _createUseCase(userId);
      final result = await useCase.createTask(data);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '创建任务失败: $e');
    }
  }

  Future<Response> _updateTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      data['id'] = id;

      final useCase = _createUseCase(userId);
      final result = await useCase.updateTask(data);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '更新任务失败: $e');
    }
  }

  Future<Response> _deleteTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.deleteTask({'id': id});

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '删除任务失败: $e');
    }
  }

  // ==================== 任务操作方法 ====================

  Future<Response> _completeTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.completeTask({'id': id});

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '完成任务失败: $e');
    }
  }

  Future<Response> _uncompleteTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.uncompleteTask({'id': id});

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '取消完成失败: $e');
    }
  }

  // ==================== 筛选方法 ====================

  Future<Response> _getTodayTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换分页参数
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.getTodayTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取今日任务失败: $e');
    }
  }

  Future<Response> _getOverdueTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换分页参数
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.getOverdueTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取过期任务失败: $e');
    }
  }

  Future<Response> _getCompletedTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换分页参数
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.getCompletedTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取已完成任务失败: $e');
    }
  }

  Future<Response> _getPendingTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换分页参数
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.getPendingTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取待办任务失败: $e');
    }
  }

  Future<Response> _searchTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = _extractQueryParams(request);

      // 转换分页参数
      if (params.containsKey('offset')) {
        params['offset'] = int.tryParse(params['offset'] as String);
      }
      if (params.containsKey('count')) {
        params['count'] = int.tryParse(params['count'] as String);
      }

      final result = await useCase.searchTasks(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '搜索任务失败: $e');
    }
  }

  // ==================== 统计方法 ====================

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.getStats({});

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      }
      return _errorResponseFromResult(result);
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }
}
