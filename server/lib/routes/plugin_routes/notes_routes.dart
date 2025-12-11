import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_notes_repository.dart';

/// Notes 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class NotesRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, NotesUseCase> _useCaseCache = {};

  NotesRoutes(this._dataService);

  /// 获取或创建指定用户的 NotesUseCase
  NotesUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerNotesRepository(
        dataService: _dataService,
        userId: userId,
      );
      return NotesUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 笔记 API ====================
    // GET /notes - 获取笔记列表
    router.get('/notes', _getNotes);

    // GET /notes/<id> - 获取单个笔记
    router.get('/notes/<id>', _getNote);

    // POST /notes - 创建笔记
    router.post('/notes', _createNote);

    // PUT /notes/<id> - 更新笔记
    router.put('/notes/<id>', _updateNote);

    // DELETE /notes/<id> - 删除笔记
    router.delete('/notes/<id>', _deleteNote);

    // POST /notes/<id>/move - 移动笔记
    router.post('/notes/<id>/move', _moveNote);

    // GET /search - 搜索笔记
    router.get('/search', _searchNotes);

    // ==================== 文件夹 API ====================
    // GET /folders - 获取文件夹列表
    router.get('/folders', _getFolders);

    // GET /folders/<id> - 获取单个文件夹
    router.get('/folders/<id>', _getFolder);

    // POST /folders - 创建文件夹
    router.post('/folders', _createFolder);

    // PUT /folders/<id> - 更新文件夹
    router.put('/folders/<id>', _updateFolder);

    // DELETE /folders/<id> - 删除文件夹
    router.delete('/folders/<id>', _deleteFolder);

    // GET /folders/<id>/notes - 获取文件夹的笔记
    router.get('/folders/<id>/notes', _getFolderNotes);

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

  // ==================== 笔记处理方法 ====================

  /// 获取笔记列表
  Future<Response> _getNotes(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['folderId'] != null) params['folderId'] = queryParams['folderId'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getNotes(params);
    return _resultToResponse(result);
  }

  /// 获取单个笔记
  Future<Response> _getNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getNoteById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建笔记
  Future<Response> _createNote(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createNote(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新笔记
  Future<Response> _updateNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateNote(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除笔记
  Future<Response> _deleteNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteNote({'id': id});
    return _resultToResponse(result);
  }

  /// 移动笔记到其他文件夹
  Future<Response> _moveNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.moveNote(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 搜索笔记
  Future<Response> _searchNotes(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['keyword'] != null) params['keyword'] = queryParams['keyword'];
    if (queryParams['tags'] != null) params['tags'] = queryParams['tags'];
    if (queryParams['folderId'] != null) params['folderId'] = queryParams['folderId'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchNotes(params);
    return _resultToResponse(result);
  }

  // ==================== 文件夹处理方法 ====================

  /// 获取文件夹列表
  Future<Response> _getFolders(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;
    if (queryParams['parentId'] != null) params['parentId'] = queryParams['parentId'];
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getFolders(params);
    return _resultToResponse(result);
  }

  /// 获取单个文件夹
  Future<Response> _getFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getFolderById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建文件夹
  Future<Response> _createFolder(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createFolder(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新文件夹
  Future<Response> _updateFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateFolder(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除文件夹
  Future<Response> _deleteFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteFolder({'id': id});
    return _resultToResponse(result);
  }

  /// 获取文件夹的笔记
  Future<Response> _getFolderNotes(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'id': id};
    final queryParams = request.url.queryParameters;
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getFolderNotes(params);
    return _resultToResponse(result);
  }
}
