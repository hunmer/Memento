import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_goods_repository.dart';

/// Goods 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class GoodsRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, GoodsUseCase> _useCaseCache = {};

  GoodsRoutes(this._dataService);

  /// 获取或创建指定用户的 GoodsUseCase
  GoodsUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerGoodsRepository(
        dataService: _dataService,
        userId: userId,
      );
      return GoodsUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 仓库 API ====================
    router.get('/warehouses', _getWarehouses);
    router.get('/warehouses/<id>', _getWarehouse);
    router.post('/warehouses', _createWarehouse);
    router.put('/warehouses/<id>', _updateWarehouse);
    router.delete('/warehouses/<id>', _deleteWarehouse);

    // ==================== 物品 API ====================
    router.get('/items', _getItems);
    router.get('/items/<id>', _getItem);
    router.post('/items', _createItem);
    router.put('/items/<id>', _updateItem);
    router.delete('/items/<id>', _deleteItem);

    // ==================== 统计/搜索 API ====================
    router.get('/stats', _getStats);
    router.get('/search', _searchItems);

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

  // ==================== 仓库处理方法 ====================

  /// 获取仓库列表
  Future<Response> _getWarehouses(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getWarehouses(params);
    return _resultToResponse(result);
  }

  /// 获取单个仓库
  Future<Response> _getWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getWarehouseById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建仓库
  Future<Response> _createWarehouse(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createWarehouse(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新仓库
  Future<Response> _updateWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateWarehouse(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除仓库
  Future<Response> _deleteWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteWarehouse({'id': id});
    return _resultToResponse(result);
  }

  // ==================== 物品处理方法 ====================

  /// 获取物品列表
  Future<Response> _getItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['warehouseId'] != null) params['warehouseId'] = queryParams['warehouseId'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getItems(params);
    return _resultToResponse(result);
  }

  /// 获取单个物品
  Future<Response> _getItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getItemById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建物品
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

  /// 更新物品
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

  /// 删除物品
  Future<Response> _deleteItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'id': id};
    final queryParams = request.url.queryParameters;
    if (queryParams['warehouseId'] != null) {
      params['warehouseId'] = queryParams['warehouseId'];
    }

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteItem(params);
    return _resultToResponse(result);
  }

  // ==================== 统计/搜索 ====================

  /// 获取统计
  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getStats({});
    return _resultToResponse(result);
  }

  /// 搜索物品
  Future<Response> _searchItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['keyword'] != null) params['keyword'] = queryParams['keyword'];
    if (queryParams['warehouseId'] != null) params['warehouseId'] = queryParams['warehouseId'];
    if (queryParams['category'] != null) params['category'] = queryParams['category'];
    if (queryParams['tags'] != null) params['tags'] = queryParams['tags'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchItems(params);
    return _resultToResponse(result);
  }
}
