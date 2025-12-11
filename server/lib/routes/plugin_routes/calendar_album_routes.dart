import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_calendar_album_repository.dart';
import '../../services/plugin_data_service.dart';

/// Calendar Album 插件 HTTP 路由
class CalendarAlbumRoutes {
  final PluginDataService _dataService;
  final Map<String, CalendarAlbumUseCase> _useCaseCache = {};

  CalendarAlbumRoutes(this._dataService);

  CalendarAlbumUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerCalendarAlbumRepository(
        dataService: _dataService,
        userId: userId,
      );
      return CalendarAlbumUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 日记操作路由
    router.get('/entries', _getEntries);
    router.get('/entries/<id>', _getEntry);
    router.get('/entries/by-date', _getEntriesByDate);
    router.get('/entries/by-tag', _getEntriesByTag);
    router.get('/entries/by-tags', _getEntriesByTags);
    router.get('/entries/search', _searchEntries);
    router.post('/entries', _createEntry);
    router.put('/entries/<id>', _updateEntry);
    router.delete('/entries/<id>', _deleteEntry);

    // 标签管理路由
    router.get('/tag-groups', _getTagGroups);
    router.put('/tag-groups', _updateTagGroups);
    router.post('/tags', _addTag);
    router.delete('/tags/<tag>', _deleteTag);
    router.get('/tags', _getTags);
    router.get('/tags/search', _searchTags);

    // 图片相关路由
    router.get('/images', _getAllImages);
    router.get('/images/<imageUrl>', _getEntryByImageUrl);

    // 统计功能路由
    router.get('/stats', _getStats);

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

  // ============ 日记路由处理 ============

  Future<Response> _getEntries(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntries(params);
    return _resultToResponse(result);
  }

  Future<Response> _getEntry(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntryById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _getEntriesByDate(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final date = request.url.queryParameters['date'];
    if (date == null) {
      return _errorResponse(400, '缺少必需参数: date');
    }

    final params = <String, dynamic>{'date': date};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntriesByDate(params);
    return _resultToResponse(result);
  }

  Future<Response> _getEntriesByTag(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final tag = request.url.queryParameters['tag'];
    if (tag == null) {
      return _errorResponse(400, '缺少必需参数: tag');
    }

    final params = <String, dynamic>{'tag': tag};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntriesByTag(params);
    return _resultToResponse(result);
  }

  Future<Response> _getEntriesByTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final tagsParam = request.url.queryParameters['tags'];
    if (tagsParam == null) {
      return _errorResponse(400, '缺少必需参数: tags');
    }

    final tags = tagsParam.split(',');
    final params = <String, dynamic>{'tags': tags};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntriesByTags(params);
    return _resultToResponse(result);
  }

  Future<Response> _searchEntries(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['date'] != null) params['date'] = q['date'];
    if (q['tags'] != null) params['tags'] = q['tags']!.split(',');
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['tagKeyword'] != null) params['tagKeyword'] = q['tagKeyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchEntries(params);
    return _resultToResponse(result);
  }

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

  Future<Response> _updateEntry(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateEntry(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteEntry(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteEntry({'id': id});
    return _resultToResponse(result);
  }

  // ============ 标签路由处理 ============

  Future<Response> _getTagGroups(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTagGroups({});
    return _resultToResponse(result);
  }

  Future<Response> _updateTagGroups(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateTagGroups(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _addTag(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.addTag(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteTag(Request request, String tag) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteTag({'tag': tag});
    return _resultToResponse(result);
  }

  Future<Response> _getTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getTags(params);
    return _resultToResponse(result);
  }

  Future<Response> _searchTags(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchTags(params);
    return _resultToResponse(result);
  }

  // ============ 图片路由处理 ============

  Future<Response> _getAllImages(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getAllImages({});
    return _resultToResponse(result);
  }

  Future<Response> _getEntryByImageUrl(Request request, String imageUrl) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getEntryByImageUrl({'imageUrl': imageUrl});
    return _resultToResponse(result);
  }

  // ============ 统计路由处理 ============

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getStats({});
    return _resultToResponse(result);
  }
}
