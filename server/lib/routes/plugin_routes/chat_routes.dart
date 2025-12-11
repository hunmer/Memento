import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_chat_repository.dart';

/// Chat 插件 HTTP 路由
///
/// 使用 Repository + UseCase 模式，与客户端共享业务逻辑
class ChatRoutes {
  final PluginDataService _dataService;

  /// 缓存每个用户的 UseCase 实例
  final Map<String, ChatUseCase> _useCaseCache = {};

  ChatRoutes(this._dataService);

  /// 获取或创建指定用户的 ChatUseCase
  ChatUseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = ServerChatRepository(
        dataService: _dataService,
        userId: userId,
      );
      return ChatUseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    // ==================== 频道 API ====================
    // GET /channels - 获取频道列表
    router.get('/channels', _getChannels);

    // POST /channels - 创建频道
    router.post('/channels', _createChannel);

    // GET /channels/<id> - 获取单个频道
    router.get('/channels/<id>', _getChannel);

    // PUT /channels/<id> - 更新频道
    router.put('/channels/<id>', _updateChannel);

    // DELETE /channels/<id> - 删除频道
    router.delete('/channels/<id>', _deleteChannel);

    // ==================== 消息 API ====================
    // GET /channels/<channelId>/messages - 获取消息列表
    router.get('/channels/<channelId>/messages', _getMessages);

    // POST /channels/<channelId>/messages - 发送消息
    router.post('/channels/<channelId>/messages', _sendMessage);

    // DELETE /channels/<channelId>/messages/<messageId> - 删除消息
    router.delete('/channels/<channelId>/messages/<messageId>', _deleteMessage);

    // ==================== 用户 API ====================
    // GET /users - 获取用户列表
    router.get('/users', _getUsers);

    // GET /users/current - 获取当前用户
    router.get('/users/current', _getCurrentUser);

    // ==================== 查找 API ====================
    // GET /find/channel - 查找频道
    router.get('/find/channel', _findChannel);

    // GET /find/message - 查找消息
    router.get('/find/message', _findMessage);

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

  // ==================== 频道处理方法 ====================

  /// 获取频道列表
  Future<Response> _getChannels(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final offset = request.url.queryParameters['offset'];
    final count = request.url.queryParameters['count'];
    if (offset != null) params['offset'] = int.tryParse(offset) ?? 0;
    if (count != null) params['count'] = int.tryParse(count) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getChannels(params);
    return _resultToResponse(result);
  }

  /// 获取单个频道
  Future<Response> _getChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getChannelById({'id': id});
    return _resultToResponse(result);
  }

  /// 创建频道
  Future<Response> _createChannel(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createChannel(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 更新频道
  Future<Response> _updateChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      updates['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateChannel(updates);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除频道
  Future<Response> _deleteChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteChannel({'id': id});
    return _resultToResponse(result);
  }

  // ==================== 消息处理方法 ====================

  /// 获取消息列表
  Future<Response> _getMessages(Request request, String channelId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{'channelId': channelId};
    final offset = request.url.queryParameters['offset'];
    final count = request.url.queryParameters['count'];
    if (offset != null) params['offset'] = int.tryParse(offset) ?? 0;
    if (count != null) params['count'] = int.tryParse(count) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getMessages(params);
    return _resultToResponse(result);
  }

  /// 发送消息
  Future<Response> _sendMessage(Request request, String channelId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['channelId'] = channelId;

      final useCase = _getUseCase(userId);
      final result = await useCase.sendMessage(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  /// 删除消息
  Future<Response> _deleteMessage(
    Request request,
    String channelId,
    String messageId,
  ) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteMessage({
      'channelId': channelId,
      'messageId': messageId,
    });
    return _resultToResponse(result);
  }

  // ==================== 用户处理方法 ====================

  /// 获取用户列表
  Future<Response> _getUsers(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getUsers({});
    return _resultToResponse(result);
  }

  /// 获取当前用户
  Future<Response> _getCurrentUser(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getCurrentUser({});
    return _resultToResponse(result);
  }

  // ==================== 查找处理方法 ====================

  /// 查找频道
  Future<Response> _findChannel(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;

    if (queryParams['field'] != null) params['field'] = queryParams['field'];
    if (queryParams['value'] != null) params['value'] = queryParams['value'];
    if (queryParams['findAll'] != null) params['findAll'] = queryParams['findAll'] == 'true';
    if (queryParams['fuzzy'] != null) params['fuzzy'] = queryParams['fuzzy'] == 'true';
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.findChannels(params);
    return _resultToResponse(result);
  }

  /// 查找消息
  Future<Response> _findMessage(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final queryParams = request.url.queryParameters;

    if (queryParams['field'] != null) params['field'] = queryParams['field'];
    if (queryParams['value'] != null) params['value'] = queryParams['value'];
    if (queryParams['channelId'] != null) params['channelId'] = queryParams['channelId'];
    if (queryParams['findAll'] != null) params['findAll'] = queryParams['findAll'] == 'true';
    if (queryParams['fuzzy'] != null) params['fuzzy'] = queryParams['fuzzy'] == 'true';
    if (queryParams['offset'] != null) params['offset'] = int.tryParse(queryParams['offset']!) ?? 0;
    if (queryParams['count'] != null) params['count'] = int.tryParse(queryParams['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.findMessages(params);
    return _resultToResponse(result);
  }
}
