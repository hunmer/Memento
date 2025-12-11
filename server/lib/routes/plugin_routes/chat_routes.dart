import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Chat 插件 HTTP 路由
class ChatRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  ChatRoutes(this._dataService);

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

  Response _paginatedResponse(
    List<dynamic> data, {
    int offset = 0,
    int count = 100,
  }) {
    final paginated = _dataService.paginate(data, offset: offset, count: count);
    return Response.ok(
      jsonEncode({
        'success': true,
        ...paginated,
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

  // ==================== 频道处理方法 ====================

  /// 获取频道列表
  Future<Response> _getChannels(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      // 读取频道列表
      final channelsListData = await _dataService.readPluginData(
        userId,
        'chat',
        'channels.json',
      );

      if (channelsListData == null) {
        return _successResponse([]);
      }

      final channelIds = (channelsListData['channels'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      // 读取每个频道的详细信息
      final channels = <Map<String, dynamic>>[];
      for (final channelId in channelIds) {
        final channelData = await _dataService.readPluginData(
          userId,
          'chat',
          'channel/$channelId.json',
        );
        if (channelData != null && channelData.containsKey('channel')) {
          channels.add(channelData['channel'] as Map<String, dynamic>);
        }
      }

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(channels, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(channels);
    } catch (e) {
      return _errorResponse(500, '获取频道失败: $e');
    }
  }

  /// 获取单个频道
  Future<Response> _getChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final channelData = await _dataService.readPluginData(
        userId,
        'chat',
        'channel/$id.json',
      );

      if (channelData == null || !channelData.containsKey('channel')) {
        return _errorResponse(404, '频道不存在');
      }

      return _successResponse(channelData['channel']);
    } catch (e) {
      return _errorResponse(500, '获取频道失败: $e');
    }
  }

  /// 创建频道
  Future<Response> _createChannel(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return _errorResponse(400, '缺少必需参数: name');
      }

      final channelId = data['id'] as String? ?? _uuid.v4();

      // 创建频道对象
      final channel = {
        'id': channelId,
        'title': name,
        'icon': data['icon'] ?? 0xe0b7, // 默认聊天图标
        'iconFontFamily': data['iconFontFamily'] ?? 'MaterialIcons',
        'backgroundColor': data['backgroundColor'] ?? '#2196F3',
        'priority': data['priority'] ?? 0,
        'groups': data['groups'] ?? <String>[],
        'lastMessageTime': DateTime.now().toIso8601String(),
        'metadata': data['metadata'],
      };

      // 保存频道信息
      await _dataService.writePluginData(
        userId,
        'chat',
        'channel/$channelId.json',
        {'channel': channel},
      );

      // 创建空消息列表
      await _dataService.writePluginData(
        userId,
        'chat',
        'messages/$channelId.json',
        {'messages': []},
      );

      // 更新频道列表
      final channelsListData = await _dataService.readPluginData(
        userId,
        'chat',
        'channels.json',
      );

      final channelIds = (channelsListData?['channels'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          <String>[];

      if (!channelIds.contains(channelId)) {
        channelIds.add(channelId);
        await _dataService.writePluginData(
          userId,
          'chat',
          'channels.json',
          {'channels': channelIds},
        );
      }

      return _successResponse(channel);
    } catch (e) {
      return _errorResponse(500, '创建频道失败: $e');
    }
  }

  /// 更新频道
  Future<Response> _updateChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      // 读取现有频道
      final channelData = await _dataService.readPluginData(
        userId,
        'chat',
        'channel/$id.json',
      );

      if (channelData == null || !channelData.containsKey('channel')) {
        return _errorResponse(404, '频道不存在');
      }

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;

      // 合并更新
      final channel = Map<String, dynamic>.from(
        channelData['channel'] as Map<String, dynamic>,
      );

      if (updates.containsKey('title')) channel['title'] = updates['title'];
      if (updates.containsKey('icon')) channel['icon'] = updates['icon'];
      if (updates.containsKey('backgroundColor')) {
        channel['backgroundColor'] = updates['backgroundColor'];
      }
      if (updates.containsKey('priority')) {
        channel['priority'] = updates['priority'];
      }
      if (updates.containsKey('groups')) channel['groups'] = updates['groups'];
      if (updates.containsKey('metadata')) {
        channel['metadata'] = updates['metadata'];
      }

      // 保存更新
      await _dataService.writePluginData(
        userId,
        'chat',
        'channel/$id.json',
        {'channel': channel},
      );

      return _successResponse(channel);
    } catch (e) {
      return _errorResponse(500, '更新频道失败: $e');
    }
  }

  /// 删除频道
  Future<Response> _deleteChannel(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      // 删除频道文件
      await _dataService.deletePluginFile(userId, 'chat', 'channel/$id.json');

      // 删除消息文件
      await _dataService.deletePluginFile(userId, 'chat', 'messages/$id.json');

      // 从频道列表中移除
      final channelsListData = await _dataService.readPluginData(
        userId,
        'chat',
        'channels.json',
      );

      if (channelsListData != null) {
        final channelIds = (channelsListData['channels'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            <String>[];

        channelIds.remove(id);
        await _dataService.writePluginData(
          userId,
          'chat',
          'channels.json',
          {'channels': channelIds},
        );
      }

      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除频道失败: $e');
    }
  }

  // ==================== 消息处理方法 ====================

  /// 获取消息列表
  Future<Response> _getMessages(Request request, String channelId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final messagesData = await _dataService.readPluginData(
        userId,
        'chat',
        'messages/$channelId.json',
      );

      if (messagesData == null) {
        return _successResponse([]);
      }

      final messages = (messagesData['messages'] as List<dynamic>?) ?? [];

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(messages, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(messages);
    } catch (e) {
      return _errorResponse(500, '获取消息失败: $e');
    }
  }

  /// 发送消息
  Future<Response> _sendMessage(Request request, String channelId) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final content = data['content'] as String?;
      if (content == null || content.isEmpty) {
        return _errorResponse(400, '缺少必需参数: content');
      }

      // 获取用户信息
      final usersData = await _dataService.readPluginData(
        userId,
        'chat',
        'users.json',
      );
      final users = (usersData?['users'] as List<dynamic>?) ?? [];
      final currentUser = users.isNotEmpty
          ? users.first as Map<String, dynamic>
          : {'id': 'default_user', 'name': '用户', 'isAI': false};

      // 创建消息
      final messageId = data['id'] as String? ?? _uuid.v4();
      final message = {
        'id': messageId,
        'content': content,
        'user': currentUser,
        'type': data['type'] ?? 'sent',
        'date': DateTime.now().toIso8601String(),
        'channelId': channelId,
        'metadata': data['metadata'],
        'replyToId': data['replyToId'],
      };

      // 读取现有消息
      final messagesData = await _dataService.readPluginData(
        userId,
        'chat',
        'messages/$channelId.json',
      );

      final messages = (messagesData?['messages'] as List<dynamic>?)?.toList() ?? [];
      messages.add(message);

      // 保存消息
      await _dataService.writePluginData(
        userId,
        'chat',
        'messages/$channelId.json',
        {'messages': messages},
      );

      return _successResponse(message);
    } catch (e) {
      return _errorResponse(500, '发送消息失败: $e');
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

    try {
      final messagesData = await _dataService.readPluginData(
        userId,
        'chat',
        'messages/$channelId.json',
      );

      if (messagesData == null) {
        return _errorResponse(404, '频道不存在');
      }

      final messages = (messagesData['messages'] as List<dynamic>?)?.toList() ?? [];
      final initialLength = messages.length;

      messages.removeWhere((m) => (m as Map<String, dynamic>)['id'] == messageId);

      if (messages.length == initialLength) {
        return _errorResponse(404, '消息不存在');
      }

      await _dataService.writePluginData(
        userId,
        'chat',
        'messages/$channelId.json',
        {'messages': messages},
      );

      return _successResponse({'deleted': true, 'id': messageId});
    } catch (e) {
      return _errorResponse(500, '删除消息失败: $e');
    }
  }

  // ==================== 用户处理方法 ====================

  /// 获取用户列表
  Future<Response> _getUsers(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final usersData = await _dataService.readPluginData(
        userId,
        'chat',
        'users.json',
      );

      final users = (usersData?['users'] as List<dynamic>?) ?? [];
      return _successResponse(users);
    } catch (e) {
      return _errorResponse(500, '获取用户失败: $e');
    }
  }

  /// 获取当前用户
  Future<Response> _getCurrentUser(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final usersData = await _dataService.readPluginData(
        userId,
        'chat',
        'users.json',
      );

      final users = (usersData?['users'] as List<dynamic>?) ?? [];
      final currentUser = users.firstWhere(
        (u) => (u as Map<String, dynamic>)['isAI'] != true,
        orElse: () => {'id': 'default_user', 'name': '用户', 'isAI': false},
      );

      return _successResponse(currentUser);
    } catch (e) {
      return _errorResponse(500, '获取当前用户失败: $e');
    }
  }

  // ==================== 查找处理方法 ====================

  /// 查找频道
  Future<Response> _findChannel(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final field = request.url.queryParameters['field'];
    final value = request.url.queryParameters['value'];
    final findAll = request.url.queryParameters['findAll'] == 'true';
    final fuzzy = request.url.queryParameters['fuzzy'] == 'true';

    if (field == null || value == null) {
      return _errorResponse(400, '缺少参数: field, value');
    }

    try {
      // 获取所有频道
      final channelsListData = await _dataService.readPluginData(
        userId,
        'chat',
        'channels.json',
      );

      final channelIds = (channelsListData?['channels'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      final channels = <Map<String, dynamic>>[];
      for (final channelId in channelIds) {
        final channelData = await _dataService.readPluginData(
          userId,
          'chat',
          'channel/$channelId.json',
        );
        if (channelData != null && channelData.containsKey('channel')) {
          channels.add(channelData['channel'] as Map<String, dynamic>);
        }
      }

      // 查找匹配
      final matches = channels.where((channel) {
        final fieldValue = channel[field]?.toString() ?? '';
        if (fuzzy) {
          return fieldValue.toLowerCase().contains(value.toLowerCase());
        }
        return fieldValue == value;
      }).toList();

      if (!findAll && matches.isNotEmpty) {
        return _successResponse(matches.first);
      }

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(matches, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(matches);
    } catch (e) {
      return _errorResponse(500, '查找频道失败: $e');
    }
  }

  /// 查找消息
  Future<Response> _findMessage(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final field = request.url.queryParameters['field'];
    final value = request.url.queryParameters['value'];
    final channelId = request.url.queryParameters['channelId'];
    final findAll = request.url.queryParameters['findAll'] == 'true';
    final fuzzy = request.url.queryParameters['fuzzy'] == 'true';

    if (field == null || value == null) {
      return _errorResponse(400, '缺少参数: field, value');
    }

    try {
      List<Map<String, dynamic>> allMessages = [];

      if (channelId != null) {
        // 在指定频道中查找
        final messagesData = await _dataService.readPluginData(
          userId,
          'chat',
          'messages/$channelId.json',
        );
        if (messagesData != null) {
          allMessages = (messagesData['messages'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
        }
      } else {
        // 在所有频道中查找
        final channelsListData = await _dataService.readPluginData(
          userId,
          'chat',
          'channels.json',
        );
        final channelIds = (channelsListData?['channels'] as List<dynamic>?)
                ?.cast<String>() ??
            [];

        for (final cid in channelIds) {
          final messagesData = await _dataService.readPluginData(
            userId,
            'chat',
            'messages/$cid.json',
          );
          if (messagesData != null) {
            final messages = (messagesData['messages'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            allMessages.addAll(messages);
          }
        }
      }

      // 查找匹配
      final matches = allMessages.where((message) {
        final fieldValue = message[field]?.toString() ?? '';
        if (fuzzy) {
          return fieldValue.toLowerCase().contains(value.toLowerCase());
        }
        return fieldValue == value;
      }).toList();

      if (!findAll && matches.isNotEmpty) {
        return _successResponse(matches.first);
      }

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(matches, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(matches);
    } catch (e) {
      return _errorResponse(500, '查找消息失败: $e');
    }
  }
}
