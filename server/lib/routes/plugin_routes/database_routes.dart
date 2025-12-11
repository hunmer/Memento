import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_database_repository.dart';
import '../../services/plugin_data_service.dart';

/// Database 插件 HTTP 路由
class DatabaseRoutes {
  final PluginDataService _dataService;
  final Map<String, DatabaseUseCase> _useCaseCache = {};

  DatabaseRoutes(this._dataService);

  DatabaseUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerDatabaseRepository(
        dataService: _dataService,
        userId: userId,
      );
      return DatabaseUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 数据库操作路由
    router.get('/databases', _getDatabases);
    router.get('/databases/<id>', _getDatabase);
    router.post('/databases', _createDatabase);
    router.put('/databases/<id>', _updateDatabase);
    router.delete('/databases/<id>', _deleteDatabase);
    router.get('/databases/search', _searchDatabases);

    // 记录操作路由
    router.get('/databases/<tableId>/records', _getRecords);
    router.get('/records/<id>', _getRecord);
    router.post('/records', _createRecord);
    router.put('/records/<id>', _updateRecord);
    router.delete('/records/<id>', _deleteRecord);
    router.get('/databases/<tableId>/records/search', _searchRecords);

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

  // ============ 数据库路由处理 ============

  Future<Response> _getDatabases(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getDatabases(params);
    return _resultToResponse(result);
  }

  Future<Response> _getDatabase(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getDatabaseById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createDatabase(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createDatabase(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateDatabase(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateDatabase(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteDatabase(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteDatabase({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchDatabases(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['nameKeyword'] != null) params['nameKeyword'] = q['nameKeyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchDatabases(params);
    return _resultToResponse(result);
  }

  // ============ 记录路由处理 ============

  Future<Response> _getRecords(Request request, String tableId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'tableId': tableId};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getRecords(params);
    return _resultToResponse(result);
  }

  Future<Response> _getRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getRecordById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createRecord(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createRecord(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateRecord(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteRecord({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchRecords(Request request, String tableId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'tableId': tableId};
    final q = request.url.queryParameters;
    if (q['fieldKeyword'] != null) params['fieldKeyword'] = q['fieldKeyword'];
    if (q['fieldName'] != null) params['fieldName'] = q['fieldName'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchRecords(params);
    return _resultToResponse(result);
  }
}
