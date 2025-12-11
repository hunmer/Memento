import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_day_repository.dart';

/// Day 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class DayRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, DayUseCase> _useCaseCache = {};

  DayRoutes(this._dataService);

  /// 获取或创建指定用户的 DayUseCase
  DayUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerDayRepository(
        dataService: _dataService,
        userId: userId,
      );
      return DayUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 纪念日 API ====================
    // GET /days - 获取纪念日列表
    router.get('/days', _getMemorialDays);

    // GET /days/<id> - 获取单个纪念日
    router.get('/days/<id>', _getMemorialDay);

    // POST /days - 创建纪念日
    router.post('/days', _createMemorialDay);

    // PUT /days/<id> - 更新纪念日
    router.put('/days/<id>', _updateMemorialDay);

    // DELETE /days/<id> - 删除纪念日
    router.delete('/days/<id>', _deleteMemorialDay);

    // POST /days/reorder - 重新排序纪念日
    router.post('/days/reorder', _reorderMemorialDays);

    // GET /search - 搜索纪念日
    router.get('/search', _searchMemorialDays);

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

  // ==================== 纪念日处理方法 ====================

  /// 获取纪念日列表
  Future<Response> _getMemorialDays(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['sortMode'] != null) params['sortMode'] = queryParams['sortMode'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getMemorialDays(params);
    return _resultToResponse(result);
  }

  /// 获取单个纪念日
  Future<Response> _getMemorialDay(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getMemorialDayById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建纪念日
  Future<Response> _createMemorialDay(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createMemorialDay(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新纪念日
  Future<Response> _updateMemorialDay(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateMemorialDay(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除纪念日
  Future<Response> _deleteMemorialDay(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteMemorialDay({'id': id});
    return _resultToResponse(result);
  }

  /// 重新排序纪念日
  Future<Response> _reorderMemorialDays(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.reorderMemorialDays(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 搜索纪念日
  Future<Response> _searchMemorialDays(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['sortMode'] != null) params['sortMode'] = queryParams['sortMode'];
    if (queryParams['startDate'] != null) params['startDate'] = queryParams['startDate'];
    if (queryParams['endDate'] != null) params['endDate'] = queryParams['endDate'];
    if (queryParams['includeExpired'] != null) {
      params['includeExpired'] = queryParams['includeExpired'] == 'true';
    }
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchMemorialDays(params);
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
