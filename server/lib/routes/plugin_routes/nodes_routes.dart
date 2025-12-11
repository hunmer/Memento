import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_nodes_repository.dart';
import '../../services/plugin_data_service.dart';

/// Nodes 插件 HTTP 路由
class NodesRoutes {
  final PluginDataService _dataService;
  final Map<String, NodesUseCase> _useCaseCache = {};

  NodesRoutes(this._dataService);

  NodesUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerNodesRepository(
        dataService: _dataService,
        userId: userId,
      );
      return NodesUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 笔记本操作路由
    router.get('/notebooks', _getNotebooks);
    router.get('/notebooks/<id>', _getNotebook);
    router.post('/notebooks', _createNotebook);
    router.put('/notebooks/<id>', _updateNotebook);
    router.delete('/notebooks/<id>', _deleteNotebook);
    router.get('/notebooks/search', _searchNotebooks);

    // 节点操作路由
    router.get('/notebooks/<notebookId>/nodes', _getNodes);
    router.get('/nodes/<id>', _getNode);
    router.post('/nodes', _createNode);
    router.put('/nodes/<id>', _updateNode);
    router.delete('/nodes/<id>', _deleteNode);
    router.get('/notebooks/<notebookId>/nodes/search', _searchNodes);

    // 树形结构操作路由
    router.post('/nodes/<id>/toggle-expansion', _toggleNodeExpansion);
    router.get('/notebooks/<notebookId>/nodes/<nodeId>/path', _getNodePath);
    router.get('/notebooks/<notebookId>/nodes/<nodeId>/siblings', _getSiblingNodes);

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

  // ============ 笔记本路由处理 ============

  Future<Response> _getNotebooks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getNotebooks(params);
    return _resultToResponse(result);
  }

  Future<Response> _getNotebook(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getNotebookById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createNotebook(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createNotebook(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateNotebook(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateNotebook(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteNotebook(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteNotebook({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchNotebooks(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['titleKeyword'] != null) params['titleKeyword'] = q['titleKeyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchNotebooks(params);
    return _resultToResponse(result);
  }

  // ============ 节点路由处理 ============

  Future<Response> _getNodes(Request request, String notebookId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'notebookId': notebookId};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getNodes(params);
    return _resultToResponse(result);
  }

  Future<Response> _getNode(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getNodeById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createNode(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createNode(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateNode(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateNode(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteNode(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteNode({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchNodes(Request request, String notebookId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'notebookId': notebookId};
    final q = request.url.queryParameters;
    if (q['titleKeyword'] != null) params['titleKeyword'] = q['titleKeyword'];
    if (q['status'] != null) params['status'] = int.tryParse(q['status']!);
    if (q['tag'] != null) params['tag'] = q['tag'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchNodes(params);
    return _resultToResponse(result);
  }

  // ============ 树形结构路由处理 ============

  Future<Response> _toggleNodeExpansion(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.toggleNodeExpansion(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _getNodePath(Request request, String notebookId, String nodeId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getNodePath({
      'notebookId': notebookId,
      'nodeId': nodeId,
    });
    return _resultToResponse(result);
  }

  Future<Response> _getSiblingNodes(Request request, String notebookId, String nodeId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getSiblingNodes({
      'notebookId': notebookId,
      'nodeId': nodeId,
    });
    return _resultToResponse(result);
  }
}
