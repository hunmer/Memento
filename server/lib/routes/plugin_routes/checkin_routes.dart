import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_checkin_repository.dart';

/// Checkin 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class CheckinRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, CheckinUseCase> _useCaseCache = {};

  CheckinRoutes(this._dataService);

  /// 获取或创建指定用户的 CheckinUseCase
  CheckinUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerCheckinRepository(
        dataService: _dataService,
        userId: userId,
      );
      return CheckinUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 打卡项目 API ====================
    // GET /items - 获取所有打卡项目
    router.get('/items', _getItems);

    // GET /items/<id> - 获取单个打卡项目
    router.get('/items/<id>', _getItem);

    // POST /items - 创建打卡项目
    router.post('/items', _createItem);

    // PUT /items/<id> - 更新打卡项目
    router.put('/items/<id>', _updateItem);

    // DELETE /items/<id> - 删除打卡项目
    router.delete('/items/<id>', _deleteItem);

    // ==================== 打卡记录 API ====================
    // POST /items/<id>/checkin - 添加打卡记录
    router.post('/items/<id>/checkin', _addCheckinRecord);

    // DELETE /items/<id>/checkin - 删除打卡记录
    router.delete('/items/<id>/checkin', _deleteCheckinRecord);

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

  // ==================== 打卡项目处理方法 ====================

  /// 获取所有打卡项目
  Future<Response> _getItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getItems(params);
    return _resultToResponse(result);
  }

  /// 获取单个打卡项目
  Future<Response> _getItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getItemById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建打卡项目
  Future<Response> _createItem(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createItem(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新打卡项目
  Future<Response> _updateItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateItem(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除打卡项目
  Future<Response> _deleteItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteItem({'id': id});
    return _resultToResponse(result);
  }

  // ==================== 打卡记录处理方法 ====================

  /// 添加打卡记录
  Future<Response> _addCheckinRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['itemId'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.addCheckinRecord(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除打卡记录
  Future<Response> _deleteCheckinRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final queryParams = request.url.queryParameters;
      final date = queryParams['date'];
      final recordIndexStr = queryParams['recordIndex'];

      if (date == null || recordIndexStr == null) {
        return _errorResponse(400, '缺少必需参数: date, recordIndex');
      }

      final recordIndex = int.tryParse(recordIndexStr);
      if (recordIndex == null) {
        return _errorResponse(400, '无效的记录索引');
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.deleteCheckinRecord({
        'itemId': id,
        'date': date,
        'recordIndex': recordIndex,
      });
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求: $e');
    }
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
