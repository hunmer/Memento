import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_timer_repository.dart';
import '../../services/plugin_data_service.dart';

/// Timer 插件 HTTP 路由
class TimerRoutes {
  final PluginDataService _dataService;
  final Map<String, TimerUseCase> _useCaseCache = {};

  TimerRoutes(this._dataService);

  TimerUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerTimerRepository(
        dataService: _dataService,
        userId: userId,
      );
      return TimerUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 任务操作路由
    router.get('/timer/tasks', _getTimerTasks);
    router.get('/timer/tasks/<id>', _getTimerTask);
    router.post('/timer/tasks', _createTimerTask);
    router.put('/timer/tasks/<id>', _updateTimerTask);
    router.delete('/timer/tasks/<id>', _deleteTimerTask);
    router.get('/timer/tasks/search', _searchTimerTasks);

    // 计时器项操作路由
    router.get('/timer/tasks/<taskId>/items', _getTimerItems);
    router.get('/timer/items/<id>', _getTimerItem);
    router.post('/timer/items', _createTimerItem);
    router.put('/timer/items/<id>', _updateTimerItem);
    router.delete('/timer/items/<id>', _deleteTimerItem);

    // 统计路由
    router.get('/timer/stats/total', _getTotalTaskCount);
    router.get('/timer/stats/running', _getRunningTaskCount);
    router.get('/timer/stats/group/<group>', _getTaskCountByGroup);

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

  // ============ 任务路由处理 ============

  Future<Response> _getTimerTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getTimerTasks(params);
    return _resultToResponse(result);
  }

  Future<Response> _getTimerTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTimerTaskById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createTimerTask(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createTimerTask(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateTimerTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateTimerTask(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteTimerTask(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteTimerTask({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchTimerTasks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['group'] != null) params['group'] = q['group'];
    if (q['isRunning'] != null) {
      params['isRunning'] = q['isRunning']!.toLowerCase() == 'true';
    }
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchTimerTasks(params);
    return _resultToResponse(result);
  }

  // ============ 计时器项路由处理 ============

  Future<Response> _getTimerItems(Request request, String taskId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'taskId': taskId};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getTimerItems(params);
    return _resultToResponse(result);
  }

  Future<Response> _getTimerItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTimerItemById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createTimerItem(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createTimerItem(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateTimerItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateTimerItem(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteTimerItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteTimerItem({'id': id});
    return _resultToResponse(result);
  }

  // ============ 统计路由处理 ============

  Future<Response> _getTotalTaskCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTotalTaskCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getRunningTaskCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getRunningTaskCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getTaskCountByGroup(Request request, String group) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTaskCountByGroup({'group': group});
    return _resultToResponse(result);
  }
}
