import 'package:flutter/services.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';

/// WatchConnectivity 服务
///
/// 处理来自 iOS Watch 应用的数据请求
class WatchConnectivityService {
  static const _channelName = 'github.hunmer.memento/watch_connectivity';

  static WatchConnectivityService? _instance;
  final MethodChannel _methodChannel;
  final ConversationService _conversationService;
  final MessageService _messageService;

  bool _isInitialized = false;

  WatchConnectivityService._({
    required ConversationService conversationService,
    required MessageService messageService,
  })  : _conversationService = conversationService,
        _messageService = messageService,
        _methodChannel = const MethodChannel(_channelName);

  /// 获取单例实例
  static WatchConnectivityService get instance {
    if (_instance == null) {
      throw Exception('WatchConnectivityService 未初始化，请先调用 initialize()');
    }
    return _instance!;
  }

  /// 初始化服务
  static void initialize({
    required ConversationService conversationService,
    required MessageService messageService,
  }) {
    if (_instance != null) {
      print('[WatchConnectivityService] 已初始化，跳过');
      return;
    }

    _instance = WatchConnectivityService._(
      conversationService: conversationService,
      messageService: messageService,
    );
    _instance!._setupMethodHandler();
  }

  /// 设置 MethodChannel 处理器
  void _setupMethodHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      print('[WatchConnectivityService] 收到请求: ${call.method}');

      try {
        switch (call.method) {
          case 'getWatchChatChannels':
            return await _getWatchChatChannels();
          case 'getWatchChatMessages':
            return await _getWatchChatMessages(call.arguments);
          default:
            throw PlatformException(
              code: 'UNIMPLEMENTED',
              message: '未实现的方法: ${call.method}',
            );
        }
      } catch (e) {
        print('[WatchConnectivityService] 处理请求失败: $e');
        rethrow;
      }
    });

    _isInitialized = true;
    print('[WatchConnectivityService] 初始化完成');
  }

  /// 获取会话列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchChatChannels() async {
    final conversations = _conversationService.conversations;

    // 转换为 watchOS 需要的格式
    final channelList = conversations
        .map((conv) => _conversationToWatchChannel(conv))
        .toList();

    print('[WatchConnectivityService] 返回 ${channelList.length} 个会话');
    return channelList;
  }

  /// 获取指定会话的消息（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchChatMessages(
    dynamic arguments,
  ) async {
    if (arguments is! Map) {
      throw ArgumentError('参数必须是 Map 类型');
    }

    final channelId = arguments['channelId'] as String?;
    if (channelId == null) {
      throw ArgumentError('缺少 channelId 参数');
    }

    final messages = await _messageService.getMessages(channelId);

    // 转换为 watchOS 需要的格式
    final messageList = messages
        .map((msg) => _messageToWatchMessage(msg))
        .toList();

    print('[WatchConnectivityService] 返回 ${messageList.length} 条消息');
    return messageList;
  }

  /// 将 Conversation 转换为 watchOS 需要的 ChatChannel 格式
  Map<String, dynamic> _conversationToWatchChannel(Conversation conv) {
    return {
      'id': conv.id,
      'name': conv.title,
      'description': conv.lastMessagePreview ?? '暂无消息',
      'unreadCount': conv.unreadCount,
      'createdAt': conv.createdAt.toIso8601String(),
      'lastActiveAt': conv.lastMessageAt.toIso8601String(),
    };
  }

  /// 将 ChatMessage 转换为 watchOS 需要的格式
  Map<String, dynamic> _messageToWatchMessage(ChatMessage msg) {
    return {
      'id': msg.id,
      'channelId': msg.conversationId,
      'content': msg.content,
      'senderId': msg.isUser ? 'me' : msg.generatedByAgentId ?? 'assistant',
      'senderName': msg.isUser ? '我' : 'AI',
      'timestamp': msg.timestamp.toIso8601String(),
      'isMe': msg.isUser,
    };
  }
}
