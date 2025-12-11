import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_contact_repository.dart';
import '../../services/plugin_data_service.dart';

/// Contact 插件 HTTP 路由
class ContactRoutes {
  final PluginDataService _dataService;
  final Map<String, ContactUseCase> _useCaseCache = {};

  ContactRoutes(this._dataService);

  ContactUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerContactRepository(
        dataService: _dataService,
        userId: userId,
      );
      return ContactUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 联系人操作路由
    router.get('/contacts', _getContacts);
    router.get('/contacts/<id>', _getContact);
    router.post('/contacts', _createContact);
    router.put('/contacts/<id>', _updateContact);
    router.delete('/contacts/<id>', _deleteContact);
    router.get('/contacts/search', _searchContacts);

    // 交互记录操作路由
    router.get('/contacts/<contactId>/interactions', _getInteractionRecords);
    router.get('/interactions/<id>', _getInteractionRecord);
    router.post('/interactions', _createInteractionRecord);
    router.put('/interactions/<id>', _updateInteractionRecord);
    router.delete('/interactions/<id>', _deleteInteractionRecord);
    router.post('/contacts/<contactId>/interactions/delete', _deleteInteractionRecordsByContactId);
    router.get('/contacts/<contactId>/interactions/search', _searchInteractionRecords);

    // 筛选与排序配置路由
    router.get('/config/filter', _getFilterConfig);
    router.post('/config/filter', _saveFilterConfig);
    router.get('/config/sort', _getSortConfig);
    router.post('/config/sort', _saveSortConfig);

    // 标签管理路由
    router.get('/tags', _getAllTags);

    // 统计操作路由
    router.get('/stats/recent-contacts', _getRecentlyContactedCount);
    router.get('/contacts/<contactId>/interactions/count', _getContactInteractionCount);
    router.get('/stats/total-contacts', _getTotalContactCount);

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

  // ============ 联系人路由处理 ============

  Future<Response> _getContacts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getContacts(params);
    return _resultToResponse(result);
  }

  Future<Response> _getContact(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getContactById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createContact(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createContact(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateContact(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateContact(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteContact(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteContact({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchContacts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['nameKeyword'] != null) params['nameKeyword'] = q['nameKeyword'];
    if (q['tags'] != null) {
      params['tags'] = q['tags']!.split(',').toList();
    }
    if (q['startDate'] != null) params['startDate'] = q['startDate'];
    if (q['endDate'] != null) params['endDate'] = q['endDate'];
    if (q['uncontactedDays'] != null) {
      params['uncontactedDays'] = int.tryParse(q['uncontactedDays']!) ?? 0;
    }
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchContacts(params);
    return _resultToResponse(result);
  }

  // ============ 交互记录路由处理 ============

  Future<Response> _getInteractionRecords(
    Request request,
    String contactId,
  ) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'contactId': contactId};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getInteractionRecords(params);
    return _resultToResponse(result);
  }

  Future<Response> _getInteractionRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getInteractionRecordById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createInteractionRecord(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createInteractionRecord(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateInteractionRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateInteractionRecord(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteInteractionRecord(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteInteractionRecord({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _deleteInteractionRecordsByContactId(
    Request request,
    String contactId,
  ) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteInteractionRecordsByContactId({
      'contactId': contactId,
    });
    return _resultToResponse(result);
  }

  Future<Response> _searchInteractionRecords(
    Request request,
    String contactId,
  ) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'contactId': contactId};
    final q = request.url.queryParameters;
    if (q['startDate'] != null) params['startDate'] = q['startDate'];
    if (q['endDate'] != null) params['endDate'] = q['endDate'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchInteractionRecords(params);
    return _resultToResponse(result);
  }

  // ============ 筛选与排序配置路由处理 ============

  Future<Response> _getFilterConfig(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getFilterConfig({});
    return _resultToResponse(result);
  }

  Future<Response> _saveFilterConfig(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.saveFilterConfig(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _getSortConfig(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getSortConfig({});
    return _resultToResponse(result);
  }

  Future<Response> _saveSortConfig(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.saveSortConfig(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  // ============ 标签管理路由处理 ============

  Future<Response> _getAllTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getAllTags({});
    return _resultToResponse(result);
  }

  // ============ 统计操作路由处理 ============

  Future<Response> _getRecentlyContactedCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getRecentlyContactedCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getContactInteractionCount(
    Request request,
    String contactId,
  ) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getContactInteractionCount({
      'contactId': contactId,
    });
    return _resultToResponse(result);
  }

  Future<Response> _getTotalContactCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTotalContactCount({});
    return _resultToResponse(result);
  }
}
