import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_openai_repository.dart';
import '../../services/plugin_data_service.dart';

/// OpenAI 插件 HTTP 路由
class OpenAIRoutes {
  final PluginDataService _dataService;
  final Map<String, OpenAIUseCase> _useCaseCache = {};

  OpenAIRoutes(this._dataService);

  OpenAIUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerOpenAIRepository(
        dataService: _dataService,
        userId: userId,
      );
      return OpenAIUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // AI 助手操作路由
    router.get('/agents', _getAgents);
    router.get('/agents/<id>', _getAgent);
    router.post('/agents', _createAgent);
    router.put('/agents/<id>', _updateAgent);
    router.delete('/agents/<id>', _deleteAgent);
    router.get('/agents/search', _searchAgents);

    // 服务商操作路由
    router.get('/service-providers', _getServiceProviders);
    router.get('/service-providers/<id>', _getServiceProvider);
    router.post('/service-providers', _createServiceProvider);
    router.put('/service-providers/<id>', _updateServiceProvider);
    router.delete('/service-providers/<id>', _deleteServiceProvider);
    router.get('/service-providers/search', _searchServiceProviders);

    // 工具应用操作路由
    router.get('/tool-apps', _getToolApps);
    router.get('/tool-apps/<id>', _getToolApp);
    router.post('/tool-apps', _createToolApp);
    router.put('/tool-apps/<id>', _updateToolApp);
    router.delete('/tool-apps/<id>', _deleteToolApp);
    router.get('/tool-apps/search', _searchToolApps);

    // 模型操作路由
    router.get('/models', _getModels);
    router.get('/models/<id>', _getModel);

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

  Map<String, dynamic>? _parseRequestBody(Request request) {
    return request.readAsString().then((body) {
      if (body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    });
  }

  Map<String, String> _parseQueryParams(Request request) {
    return request.url.queryParameters;
  }

  // ============ AI 助手路由处理 ============

  Future<Response> _getAgents(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.getAgents(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取 AI 助手列表失败: $e');
    }
  }

  Future<Response> _getAgent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.getAgentById(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取 AI 助手失败: $e');
    }
  }

  Future<Response> _createAgent(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.createAgent(body);

      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(500, '创建 AI 助手失败: $e');
    }
  }

  Future<Response> _updateAgent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      body['id'] = id;
      final useCase = _getUseCase(userId);
      final result = await useCase.updateAgent(body);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '更新 AI 助手失败: $e');
    }
  }

  Future<Response> _deleteAgent(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.deleteAgent(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '删除 AI 助手失败: $e');
    }
  }

  Future<Response> _searchAgents(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.searchAgents(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '搜索 AI 助手失败: $e');
    }
  }

  // ============ 服务商路由处理 ============

  Future<Response> _getServiceProviders(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.getServiceProviders(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取服务商列表失败: $e');
    }
  }

  Future<Response> _getServiceProvider(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.getServiceProviderById(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取服务商失败: $e');
    }
  }

  Future<Response> _createServiceProvider(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.createServiceProvider(body);

      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(500, '创建服务商失败: $e');
    }
  }

  Future<Response> _updateServiceProvider(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      body['id'] = id;
      final useCase = _getUseCase(userId);
      final result = await useCase.updateServiceProvider(body);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '更新服务商失败: $e');
    }
  }

  Future<Response> _deleteServiceProvider(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.deleteServiceProvider(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '删除服务商失败: $e');
    }
  }

  Future<Response> _searchServiceProviders(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.searchServiceProviders(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '搜索服务商失败: $e');
    }
  }

  // ============ 工具应用路由处理 ============

  Future<Response> _getToolApps(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.getToolApps(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取工具应用列表失败: $e');
    }
  }

  Future<Response> _getToolApp(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.getToolAppById(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取工具应用失败: $e');
    }
  }

  Future<Response> _createToolApp(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      final useCase = _getUseCase(userId);
      final result = await useCase.createToolApp(body);

      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(500, '创建工具应用失败: $e');
    }
  }

  Future<Response> _updateToolApp(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final body = await _parseRequestBody(request);
      if (body == null) {
        return _errorResponse(400, '请求体格式错误');
      }

      body['id'] = id;
      final useCase = _getUseCase(userId);
      final result = await useCase.updateToolApp(body);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '更新工具应用失败: $e');
    }
  }

  Future<Response> _deleteToolApp(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.deleteToolApp(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '删除工具应用失败: $e');
    }
  }

  Future<Response> _searchToolApps(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.searchToolApps(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '搜索工具应用失败: $e');
    }
  }

  // ============ 模型路由处理 ============

  Future<Response> _getModels(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = _parseQueryParams(request);
      final useCase = _getUseCase(userId);
      final result = await useCase.getModels(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取模型列表失败: $e');
    }
  }

  Future<Response> _getModel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) {
      return _errorResponse(401, '未授权访问');
    }

    try {
      final params = {'id': id};
      final useCase = _getUseCase(userId);
      final result = await useCase.getModelById(params);

      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(500, '获取模型失败: $e');
    }
  }
}
