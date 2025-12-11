import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_activity_repository.dart';

/// Activity 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class ActivityRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, ActivityUseCase> _useCaseCache = {};

  ActivityRoutes(this._dataService);

  /// 获取或创建指定用户的 ActivityUseCase
  ActivityUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerActivityRepository(
        dataService: _dataService,
        userId: userId,
      );
      return ActivityUseCase(repository);
    });
  }

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
          if (failure.code != null) 'code': failure.code,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// 将错误码映射到 HTTP 状态码
  int _errorCodeToStatus(String? code) {
    switch (code) {
      case ErrorCodes.notFound:
        return 404;
      case ErrorCodes.invalidParams:
      case ErrorCodes.validationError:
        return 400;
      case ErrorCodes.unauthorized:
        return 401;
      case ErrorCodes.forbidden:
        return 403;
      case ErrorCodes.conflict:
        return 409;
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

  // ==================== 活动处理方法 ====================

  /// 获取活动列表
  Future<Response> _getActivities(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final params = <String, dynamic>{};

      // 提取查询参数
      final date = request.url.queryParameters['date'];
      if (date != null) params['date'] = date;

      final offset = request.url.queryParameters['offset'];
      if (offset != null) params['offset'] = int.tryParse(offset);

      final count = request.url.queryParameters['count'];
      if (count != null) params['count'] = int.tryParse(count);

      final useCase = _getUseCase(userId);
      final result = await useCase.getActivities(params);
      return _resultToResponse(result);
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
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createActivity(params);
      return _resultToResponse(result, successStatus: 201);
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
      final params = jsonDecode(body) as Map<String, dynamic>;

      // 添加 ID 到参数
      params['id'] = id;

      // 如果 body 中没有 date，尝试从查询参数获取
      if (!params.containsKey('date')) {
        final date = request.url.queryParameters['date'];
        if (date != null) params['date'] = date;
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.updateActivity(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '更新活动失败: $e');
    }
  }

  /// 删除活动
  Future<Response> _deleteActivity(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final params = <String, dynamic>{
        'id': id,
      };

      // 从查询参数获取日期
      final date = request.url.queryParameters['date'];
      if (date != null) params['date'] = date;

      final useCase = _getUseCase(userId);
      final result = await useCase.deleteActivity(params);
      return _resultToResponse(result);
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
      final useCase = _getUseCase(userId);
      final result = await useCase.getTodayStats({});
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }

  /// 获取日期范围统计
  Future<Response> _getRangeStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final params = <String, dynamic>{};

      final startDate = request.url.queryParameters['startDate'];
      if (startDate != null) params['startDate'] = startDate;

      final endDate = request.url.queryParameters['endDate'];
      if (endDate != null) params['endDate'] = endDate;

      final useCase = _getUseCase(userId);
      final result = await useCase.getRangeStats(params);
      return _resultToResponse(result);
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
      final useCase = _getUseCase(userId);
      final result = await useCase.getTagGroups({});
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取标签分组失败: $e');
    }
  }

  /// 获取最近标签
  Future<Response> _getRecentTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _getUseCase(userId);
      final result = await useCase.getRecentTags({});
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取最近标签失败: $e');
    }
  }
}
