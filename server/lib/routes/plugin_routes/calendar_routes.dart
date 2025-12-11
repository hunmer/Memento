import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_calendar_repository.dart';
import '../../services/plugin_data_service.dart';

/// Calendar 插件 HTTP 路由
class CalendarRoutes {
  final PluginDataService _dataService;
  final Map<String, CalendarUseCase> _useCaseCache = {};

  CalendarRoutes(this._dataService);

  CalendarUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerCalendarRepository(
        dataService: _dataService,
        userId: userId,
      );
      return CalendarUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 事件操作路由
    router.get('/events', _getEvents);
    router.get('/events/<id>', _getEvent);
    router.post('/events', _createEvent);
    router.put('/events/<id>', _updateEvent);
    router.delete('/events/<id>', _deleteEvent);
    router.post('/events/<id>/complete', _completeEvent);
    router.get('/events/search', _searchEvents);

    // 已完成事件操作路由
    router.get('/events/completed', _getCompletedEvents);
    router.get('/events/completed/<id>', _getCompletedEvent);
    router.post('/events/<id>/restore', _restoreCompletedEvent);
    router.delete('/events/completed/<id>', _deleteCompletedEvent);

    return router;
  }

  // ============ 辅助方法 ============

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _resultToResponse<T>(Result<T> result, {int successStatus = 200}) {
    if (result.isSuccess) {
      return Response(
        successStatus,
        body: jsonEncode({
          'success': true,
          'data': result.dataOrNull,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      final failure = result as Failure<T>;
      final statusCode = _errorCodeToStatus(failure.code);
      return Response(
        statusCode,
        body: jsonEncode({
          'success': false,
          'error': failure.message,
          'code': failure.code,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  int _errorCodeToStatus(String? code) {
    switch (code) {
      case ErrorCodes.notFound:
        return 404;
      case ErrorCodes.invalidParams:
        return 400;
      case ErrorCodes.unauthorized:
        return 401;
      case ErrorCodes.forbidden:
        return 403;
      default:
        return 500;
    }
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

  // ============ 事件路由处理 ============

  Future<Response> _getEvents(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEvents(params);
    return _resultToResponse(result);
  }

  Future<Response> _getEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getEventById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createEvent(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      // 转换日期时间字符串为 DateTime 对象
      if (params['startTime'] is String) {
        params['startTime'] = DateTime.parse(params['startTime'] as String);
      }
      if (params['endTime'] is String) {
        params['endTime'] = DateTime.parse(params['endTime'] as String);
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.createEvent(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      // 转换日期时间字符串为 DateTime 对象
      if (params['startTime'] is String) {
        params['startTime'] = DateTime.parse(params['startTime'] as String);
      }
      if (params['endTime'] is String) {
        params['endTime'] = DateTime.parse(params['endTime'] as String);
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.updateEvent(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteEvent({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _completeEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      // 转换日期时间字符串为 DateTime 对象
      if (params['completedTime'] is String) {
        params['completedTime'] = DateTime.parse(params['completedTime'] as String);
      } else {
        params['completedTime'] = DateTime.now();
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.completeEvent(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _searchEvents(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;

    if (q['startDate'] != null) {
      params['startDate'] = DateTime.parse(q['startDate']!);
    }
    if (q['endDate'] != null) {
      params['endDate'] = DateTime.parse(q['endDate']!);
    }
    if (q['source'] != null) params['source'] = q['source'];
    if (q['titleKeyword'] != null) params['titleKeyword'] = q['titleKeyword'];
    if (q['includeCompleted'] != null) {
      params['includeCompleted'] = q['includeCompleted'] == 'true';
    }
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchEvents(params);
    return _resultToResponse(result);
  }

  // ============ 已完成事件路由处理 ============

  Future<Response> _getCompletedEvents(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getCompletedEvents(params);
    return _resultToResponse(result);
  }

  Future<Response> _getCompletedEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getCompletedEventById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _restoreCompletedEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.restoreCompletedEvent({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _deleteCompletedEvent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteCompletedEvent({'id': id});
    return _resultToResponse(result);
  }
}
