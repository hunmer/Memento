import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_bill_repository.dart';

/// Bill 插件 HTTP 路由
class BillRoutes {
  final PluginDataService _dataService;

  BillRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 账户 API ====================
    router.get('/accounts', _getAccounts);
    router.get('/accounts/<id>', _getAccount);
    router.post('/accounts', _createAccount);
    router.put('/accounts/<id>', _updateAccount);
    router.delete('/accounts/<id>', _deleteAccount);

    // ==================== 账单 API ====================
    router.get('/bills', _getBills);
    router.get('/bills/<id>', _getBill);
    router.post('/bills', _createBill);
    router.put('/bills/<id>', _updateBill);
    router.delete('/bills/<id>', _deleteBill);

    // ==================== 统计 API ====================
    router.get('/stats', _getStats);
    router.get('/stats/category', _getCategoryStats);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

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

  /// 创建 UseCase 实例
  BillUseCase _createUseCase(String userId) {
    final repository = ServerBillRepository(
      dataService: _dataService,
      userId: userId,
    );
    return BillUseCase(repository);
  }

  // ==================== 账户处理方法 ====================

  Future<Response> _getAccounts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = {
        'offset': int.tryParse(request.url.queryParameters['offset'] ?? ''),
        'count': int.tryParse(request.url.queryParameters['count'] ?? ''),
      };

      final result = await useCase.getAccounts(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '获取账户失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取账户失败: $e');
    }
  }

  Future<Response> _getAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.getAccountById({'id': id});

      if (result.isSuccess) {
        final data = result.dataOrNull;
        if (data == null) {
          return _errorResponse(404, '账户不存在');
        }
        return _successResponse(data);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '获取账户失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取账户失败: $e');
    }
  }

  Future<Response> _createAccount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _createUseCase(userId);
      final result = await useCase.createAccount(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.invalidParams ? 400 : 500,
          failure?.message ?? '创建账户失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '创建账户失败: $e');
    }
  }

  Future<Response> _updateAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _createUseCase(userId);
      final result = await useCase.updateAccount(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '更新账户失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '更新账户失败: $e');
    }
  }

  Future<Response> _deleteAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.deleteAccount({'id': id});

      if (result.isSuccess) {
        return _successResponse({'deleted': true, 'id': id});
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '删除账户失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '删除账户失败: $e');
    }
  }

  // ==================== 账单处理方法 ====================

  Future<Response> _getBills(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = {
        'accountId': request.url.queryParameters['accountId'],
        'startDate': request.url.queryParameters['startDate'],
        'endDate': request.url.queryParameters['endDate'],
        'offset': int.tryParse(request.url.queryParameters['offset'] ?? ''),
        'count': int.tryParse(request.url.queryParameters['count'] ?? ''),
      };

      final result = await useCase.getBills(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '获取账单失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取账单失败: $e');
    }
  }

  Future<Response> _getBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.getBillById({'id': id});

      if (result.isSuccess) {
        final data = result.dataOrNull;
        if (data == null) {
          return _errorResponse(404, '账单不存在');
        }
        return _successResponse(data);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '获取账单失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取账单失败: $e');
    }
  }

  Future<Response> _createBill(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _createUseCase(userId);
      final result = await useCase.createBill(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        final statusCode = failure?.code == ErrorCodes.invalidParams
            ? 400
            : failure?.code == ErrorCodes.notFound
                ? 404
                : 500;
        return _errorResponse(
          statusCode,
          failure?.message ?? '创建账单失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '创建账单失败: $e');
    }
  }

  Future<Response> _updateBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _createUseCase(userId);
      final result = await useCase.updateBill(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '更新账单失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '更新账单失败: $e');
    }
  }

  Future<Response> _deleteBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final result = await useCase.deleteBill({'id': id});

      if (result.isSuccess) {
        return _successResponse({'deleted': true, 'id': id});
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          failure?.code == ErrorCodes.notFound ? 404 : 500,
          failure?.message ?? '删除账单失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '删除账单失败: $e');
    }
  }

  // ==================== 统计方法 ====================

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = {
        'startDate': request.url.queryParameters['startDate'],
        'endDate': request.url.queryParameters['endDate'],
      };

      final result = await useCase.getStats(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          500,
          failure?.message ?? '获取统计失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }

  Future<Response> _getCategoryStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final useCase = _createUseCase(userId);
      final params = {
        'type': request.url.queryParameters['type'],
        'startDate': request.url.queryParameters['startDate'],
        'endDate': request.url.queryParameters['endDate'],
      };

      final result = await useCase.getCategoryStats(params);

      if (result.isSuccess) {
        return _successResponse(result.dataOrNull);
      } else {
        final failure = result.errorOrNull;
        return _errorResponse(
          500,
          failure?.message ?? '获取分类统计失败',
        );
      }
    } catch (e) {
      return _errorResponse(500, '获取分类统计失败: $e');
    }
  }
}
