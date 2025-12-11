import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../repositories/server_agent_chat_repository.dart';
import '../../services/plugin_data_service.dart';

/// Agent Chat 插件 HTTP 路由
class AgentChatRoutes {
  final PluginDataService _dataService;
  final Map<String, AgentChatUseCase> _useCaseCache = {};

  AgentChatRoutes(this._dataService);

  AgentChatUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerAgentChatRepository(
        dataService: _dataService,
        userId: userId,
      );
      return AgentChatUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // 会话操作路由
    router.get('/conversations', _getConversations);
    router.get('/conversations/<id>', _getConversation);
    router.post('/conversations', _createConversation);
    router.put('/conversations/<id>', _updateConversation);
    router.delete('/conversations/<id>', _deleteConversation);
    router.get('/conversations/search', _searchConversations);

    // 分组操作路由
    router.get('/groups', _getGroups);
    router.get('/groups/<id>', _getGroup);
    router.post('/groups', _createGroup);
    router.put('/groups/<id>', _updateGroup);
    router.delete('/groups/<id>', _deleteGroup);

    // 消息操作路由
    router.get('/conversations/<conversationId>/messages', _getMessages);
    router.get('/messages/<id>', _getMessage);
    router.post('/messages', _createMessage);
    router.put('/messages/<id>', _updateMessage);
    router.delete('/messages/<id>', _deleteMessage);
    router.get('/conversations/<conversationId>/messages/search', _searchMessages);

    // 工具模板操作路由
    router.get('/templates', _getToolTemplates);
    router.get('/templates/<id>', _getToolTemplate);
    router.post('/templates', _createToolTemplate);
    router.put('/templates/<id>', _updateToolTemplate);
    router.delete('/templates/<id>', _deleteToolTemplate);
    router.get('/templates/search', _searchToolTemplates);
    router.post('/templates/<id>/use', _markTemplateAsUsed);

    // 统计路由
    router.get('/stats/conversations/count', _getConversationCount);
    router.get('/conversations/<conversationId>/messages/count', _getMessageCount);
    router.get('/stats/templates/usage', _getTemplateUsageStats);

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

  // ============ 会话路由处理 ============

  Future<Response> _getConversations(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getConversations(params);
    return _resultToResponse(result);
  }

  Future<Response> _getConversation(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getConversationById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createConversation(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createConversation(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateConversation(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateConversation(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteConversation(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteConversation({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchConversations(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['agentId'] != null) params['agentId'] = q['agentId'];
    if (q['groupId'] != null) params['groupId'] = q['groupId'];
    if (q['isPinned'] != null) params['isPinned'] = q['isPinned'] == 'true';
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchConversations(params);
    return _resultToResponse(result);
  }

  // ============ 分组路由处理 ============

  Future<Response> _getGroups(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getGroups({});
    return _resultToResponse(result);
  }

  Future<Response> _getGroup(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getGroupById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createGroup(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createGroup(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateGroup(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateGroup(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteGroup(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteGroup({'id': id});
    return _resultToResponse(result);
  }

  // ============ 消息路由处理 ============

  Future<Response> _getMessages(Request request, String conversationId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'conversationId': conversationId};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getMessages(params);
    return _resultToResponse(result);
  }

  Future<Response> _getMessage(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getMessageById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createMessage(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createMessage(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateMessage(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateMessage(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteMessage(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteMessage({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchMessages(Request request, String conversationId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'conversationId': conversationId};
    final q = request.url.queryParameters;
    if (q['startTime'] != null) params['startTime'] = q['startTime'];
    if (q['endTime'] != null) params['endTime'] = q['endTime'];
    if (q['isUser'] != null) params['isUser'] = q['isUser'] == 'true';
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchMessages(params);
    return _resultToResponse(result);
  }

  // ============ 工具模板路由处理 ============

  Future<Response> _getToolTemplates(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getToolTemplates(params);
    return _resultToResponse(result);
  }

  Future<Response> _getToolTemplate(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getToolTemplateById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createToolTemplate(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createToolTemplate(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateToolTemplate(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateToolTemplate(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteToolTemplate(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteToolTemplate({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _searchToolTemplates(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['keyword'] != null) params['keyword'] = q['keyword'];
    if (q['tags'] != null) params['tags'] = q['tags']!.split(',');
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.searchToolTemplates(params);
    return _resultToResponse(result);
  }

  Future<Response> _markTemplateAsUsed(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.markTemplateAsUsed({'id': id});
    return _resultToResponse(result);
  }

  // ============ 统计路由处理 ============

  Future<Response> _getConversationCount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getConversationCount({});
    return _resultToResponse(result);
  }

  Future<Response> _getMessageCount(Request request, String conversationId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getMessageCount({'conversationId': conversationId});
    return _resultToResponse(result);
  }

  Future<Response> _getTemplateUsageStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getTemplateUsageStats({});
    return _resultToResponse(result);
  }
}
