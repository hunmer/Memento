import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_diary_repository.dart';

/// Diary 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class DiaryRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, DiaryUseCase> _useCaseCache = {};

  DiaryRoutes(this._dataService);

  /// 获取或创建指定用户的 DiaryUseCase
  DiaryUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerDiaryRepository(
        dataService: _dataService,
        userId: userId,
      );
      return DiaryUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 日记 API ====================
    // GET /entries - 获取日记列表
    router.get('/entries', _getEntries);

    // GET /entries/<date> - 获取指定日期的日记
    router.get('/entries/<date>', _getEntry);

    // POST /entries - 创建日记
    router.post('/entries', _createEntry);

    // PUT /entries/<date> - 更新日记
    router.put('/entries/<date>', _updateEntry);

    // DELETE /entries/<date> - 删除日记
    router.delete('/entries/<date>', _deleteEntry);

    // GET /search - 搜索日记
    router.get('/search', _searchEntries);

    // ==================== 统计 API ====================
    // GET /stats - 获取统计信息
    router.get('/stats', _getStats);

    // GET /stats/today - 获取今日字数
    router.get('/stats/today', _getTodayWordCount);

    // GET /stats/month - 获取本月字数
    router.get('/stats/month', _getMonthWordCount);

    // GET /stats/progress - 获取本月进度
    router.get('/stats/progress', _getMonthProgress);

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

  // ==================== 日记处理方法 ====================

  /// 获取日记列表
  Future<Response> _getEntries(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['startDate'] != null) params['startDate'] = queryParams['startDate'];
    if (queryParams['endDate'] != null) params['endDate'] = queryParams['endDate'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntries(params);
    return _resultToResponse(result);
  }

  /// 获取指定日期的日记
  Future<Response> _getEntry(Request request, String date) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntryByDate({'date': date});
    return _resultToResponse(result);
  }

  /// 创建日记
  Future<Response> _createEntry(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createEntry(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新日记
  Future<Response> _updateEntry(Request request, String date) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['date'] = date;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateEntry(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除日记
  Future<Response> _deleteEntry(Request request, String date) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteEntry({'date': date});
    return _resultToResponse(result);
  }

  /// 搜索日记
  Future<Response> _searchEntries(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['startDate'] != null) params['startDate'] = queryParams['startDate'];
    if (queryParams['endDate'] != null) params['endDate'] = queryParams['endDate'];
    if (queryParams['keyword'] != null) params['keyword'] = queryParams['keyword'];
    if (queryParams['mood'] != null) params['mood'] = queryParams['mood'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchEntries(params);
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

  /// 获取今日字数
  Future<Response> _getTodayWordCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTodayWordCount({});
    return _resultToResponse(result);
  }

  /// 获取本月字数
  Future<Response> _getMonthWordCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getMonthWordCount({});
    return _resultToResponse(result);
  }

  /// 获取本月进度
  Future<Response> _getMonthProgress(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getMonthProgress({});
    return _resultToResponse(result);
  }
}
