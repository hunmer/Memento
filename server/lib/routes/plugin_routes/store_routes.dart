import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_store_repository.dart';
import '../../services/plugin_data_service.dart';

/// Store 插件 HTTP 路由
class StoreRoutes {
  final PluginDataService _dataService;
  final Map<String, StoreUseCase> _useCaseCache = {};

  StoreRoutes(this._dataService);

  StoreUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerStoreRepository(
        dataService: _dataService,
        userId: userId,
      );
      return StoreUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 商品操作路由
    router.get('/products', _getProducts);
    router.get('/products/<id>', _getProduct);
    router.post('/products', _createProduct);
    router.put('/products/<id>', _updateProduct);
    router.delete('/products/<id>', _deleteProduct);
    router.post('/products/<id>/archive', _archiveProduct);
    router.post('/products/<id>/restore', _restoreProduct);
    router.get('/products/archived', _getArchivedProducts);
    router.get('/products/search', _searchProducts);

    // 积分操作路由
    router.get('/points', _getPointsInfo);
    router.post('/points', _addPoints);
    router.delete('/points/logs', _clearPointsLogs);
    router.get('/points/logs/search', _searchPointsLogs);

    // 用户物品操作路由
    router.get('/user-items', _getUserItems);
    router.get('/user-items/<id>', _getUserItem);
    router.post('/user-items/exchange', _exchangeProduct);
    router.post('/user-items/<id>/use', _useItem);
    router.delete('/user-items', _clearUserItems);
    router.get('/user-items/search', _searchUserItems);

    // 已使用物品操作路由
    router.get('/used-items', _getUsedItems);

    // 统计查询路由
    router.get('/stats/products-count', _getProductsCount);
    router.get('/stats/user-items-count', _getUserItemsCount);
    router.get('/stats/expiring-items-count', _getExpiringItemsCount);

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
      case ErrorCodes.validationError:
        return 422;
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

  // ============ 商品路由处理 ============

  Future<Response> _getProducts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getProducts(params);
    return _resultToResponse(result);
  }

  Future<Response> _getProduct(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getProductById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createProduct(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createProduct(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateProduct(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateProduct(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteProduct(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteProduct({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _archiveProduct(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.archiveProduct({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _restoreProduct(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.restoreProduct({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _getArchivedProducts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getArchivedProducts(params);
    return _resultToResponse(result);
  }

  Future<Response> _searchProducts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['nameKeyword'] != null) params['nameKeyword'] = q['nameKeyword'];
    if (q['minPrice'] != null) params['minPrice'] = int.tryParse(q['minPrice']!) ?? 0;
    if (q['maxPrice'] != null) params['maxPrice'] = int.tryParse(q['maxPrice']!) ?? 0;
    if (q['includeArchived'] != null) params['includeArchived'] = q['includeArchived'] == 'true';
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchProducts(params);
    return _resultToResponse(result);
  }

  // ============ 积分路由处理 ============

  Future<Response> _getPointsInfo(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getPointsInfo(params);
    return _resultToResponse(result);
  }

  Future<Response> _addPoints(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.addPoints(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _clearPointsLogs(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.clearPointsLogs({});
    return _resultToResponse(result);
  }

  Future<Response> _searchPointsLogs(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchPointsLogs(params);
    return _resultToResponse(result);
  }

  // ============ 用户物品路由处理 ============

  Future<Response> _getUserItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getUserItems(params);
    return _resultToResponse(result);
  }

  Future<Response> _getUserItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getUserItemById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _exchangeProduct(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.exchangeProduct(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _useItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.useItem({'itemId': id});
    return _resultToResponse(result);
  }

  Future<Response> _clearUserItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.clearUserItems({});
    return _resultToResponse(result);
  }

  Future<Response> _searchUserItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['productId'] != null) params['productId'] = q['productId'];
    if (q['includeExpired'] != null) params['includeExpired'] = q['includeExpired'] == 'true';
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchUserItems(params);
    return _resultToResponse(result);
  }

  // ============ 已使用物品路由处理 ============

  Future<Response> _getUsedItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getUsedItems(params);
    return _resultToResponse(result);
  }

  // ============ 统计查询路由处理 ============

  Future<Response> _getProductsCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getProductsCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getUserItemsCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getUserItemsCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getExpiringItemsCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getExpiringItemsCount({});
    return _resultToResponse(result);
  }
}
