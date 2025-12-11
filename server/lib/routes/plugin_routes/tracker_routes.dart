import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_tracker_repository.dart';

/// Tracker 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class TrackerRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, TrackerUseCase> _useCaseCache = {};

  TrackerRoutes(this._dataService);

  /// 获取或创建指定用户的 TrackerUseCase
  TrackerUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerTrackerRepository(
        dataService: _dataService,
        userId: userId,
      );
      return TrackerUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 目标 API ====================
    // GET /goals - 获取目标列表
    router.get('/goals', _getGoals);

    // GET /goals/<id> - 获取单个目标
    router.get('/goals/<id>', _getGoal);

    // POST /goals - 创建目标
    router.post('/goals', _createGoal);

    // PUT /goals/<id> - 更新目标
    router.put('/goals/<id>', _updateGoal);

    // DELETE /goals/<id> - 删除目标
    router.delete('/goals/<id>', _deleteGoal);

    // GET /search/goals - 搜索目标
    router.get('/search/goals', _searchGoals);

    // GET /groups - 获取所有分组
    router.get('/groups', _getAllGroups);

    // ==================== 记录 API ====================
    // GET /goals/<id>/records - 获取目标的记录列表
    router.get('/goals/<id>/records', _getRecordsForGoal);

    // POST /records - 添加记录
    router.post('/records', _addRecord);

    // DELETE /records/<id> - 删除记录
    router.delete('/records/<id>', _deleteRecord);

    // DELETE /goals/<id>/records - 清空目标的所有记录
    router.delete('/goals/<id>/records', _clearRecordsForGoal);

    // GET /search/records - 搜索记录
    router.get('/search/records', _searchRecords);

    // ==================== 统计 API ====================
    // GET /stats - 获取统计信息
    router.get('/stats', _getStats);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  /// 将 Result 转换为 HTTP Response
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

  /// 错误码映射到 HTTP 状态码
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

  // ==================== 目标处理方法 ====================

  /// 获取目标列表
  Future<Response> _getGoals(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['status'] != null) params['status'] = queryParams['status'];
    if (queryParams['group'] != null) params['group'] = queryParams['group'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getGoals(params);
    return _resultToResponse(result);
  }

  /// 获取单个目标
  Future<Response> _getGoal(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getGoalById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建目标
  Future<Response> _createGoal(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createGoal(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新目标
  Future<Response> _updateGoal(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateGoal(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除目标
  Future<Response> _deleteGoal(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteGoal({'id': id});
    return _resultToResponse(result);
  }

  /// 搜索目标
  Future<Response> _searchGoals(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['status'] != null) params['status'] = queryParams['status'];
    if (queryParams['group'] != null) params['group'] = queryParams['group'];
    if (queryParams['field'] != null) params['field'] = queryParams['field'];
    if (queryParams['value'] != null) params['value'] = queryParams['value'];
    if (queryParams['fuzzy'] != null) params['fuzzy'] = queryParams['fuzzy'] == 'true';
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchGoals(params);
    return _resultToResponse(result);
  }

  /// 获取所有分组
  Future<Response> _getAllGroups(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getAllGroups({});
    return _resultToResponse(result);
  }

  // ==================== 记录处理方法 ====================

  /// 获取目标的记录列表
  Future<Response> _getRecordsForGoal(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'goalId': id};
    final queryParams = request.url.queryParameters;
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getRecordsForGoal(params);
    return _resultToResponse(result);
  }

  /// 添加记录
  Future<Response> _addRecord(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.addRecord(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除记录
  Future<Response> _deleteRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteRecord({'recordId': id});
    return _resultToResponse(result);
  }

  /// 清空目标的所有记录
  Future<Response> _clearRecordsForGoal(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.clearRecordsForGoal({'goalId': id});
    return _resultToResponse(result);
  }

  /// 搜索记录
  Future<Response> _searchRecords(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['goalId'] != null) params['goalId'] = queryParams['goalId'];
    if (queryParams['startDate'] != null) params['startDate'] = queryParams['startDate'];
    if (queryParams['endDate'] != null) params['endDate'] = queryParams['endDate'];
    if (queryParams['field'] != null) params['field'] = queryParams['field'];
    if (queryParams['value'] != null) params['value'] = queryParams['value'];
    if (queryParams['fuzzy'] != null) params['fuzzy'] = queryParams['fuzzy'] == 'true';
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchRecords(params);
    return _resultToResponse(result);
  }

  // ==================== 统计处理方法 ====================

  /// 获取统计信息
  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getStats({});
    return _resultToResponse(result);
  }
}
