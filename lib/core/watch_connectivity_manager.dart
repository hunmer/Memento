//
//  WatchConnectivityManager.dart
//  Memento - Watch Connectivity Manager
//
//  Created by Claude on 2026/3/11.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../plugins/chat/chat_plugin.dart';
import '../plugins/chat/models/channel.dart';
import '../plugins/chat/models/message.dart';
import '../plugins/chat/models/user.dart';

/// 手表连接管理器 - 响应手表的数据请求
class WatchConnectivityManager extends ChangeNotifier {
  static WatchConnectivityManager? _instance;

  factory WatchConnectivityManager() {
    _instance ??= WatchConnectivityManager._internal();
    return _instance!;
  }

  WatchConnectivityManager._internal();

  final WatchConnectivity _watchConnectivity = WatchConnectivity();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _contextSubscription;
  Timer? _reachableCheckTimer;

  bool _isInitialized = false;
  bool _isReachable = false;
  bool _isPaired = false;

  bool get isInitialized => _isInitialized;
  bool get isReachable => _isReachable;
  bool get isPaired => _isPaired;

  /// 初始化手表连接
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 监听消息
      _messageSubscription = _watchConnectivity.messageStream.listen(_handleMessage);

      // 监听上下文变化
      _contextSubscription = _watchConnectivity.contextStream.listen(_handleContextUpdate);

      // 检查连接状态
      _isPaired = await _watchConnectivity.isPaired;
      _isReachable = await _watchConnectivity.isReachable;

      // 定期检查可达性状态（watch_connectivity 插件不支持 stream）
      _startReachabilityCheck();

      _isInitialized = true;
      debugPrint('WatchConnectivityManager initialized');
    } catch (e) {
      debugPrint('Failed to initialize WatchConnectivityManager: $e');
    }
  }

  /// 启动可达性检查定时器
  void _startReachabilityCheck() {
    _reachableCheckTimer?.cancel();
    _reachableCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateReachability(),
    );
  }

  /// 更新可达性状态
  Future<void> _updateReachability() async {
    try {
      final reachable = await _watchConnectivity.isReachable;
      if (reachable != _isReachable) {
        _isReachable = reachable;
        notifyListeners();
        debugPrint('Watch reachable changed: $reachable');
      }
    } catch (e) {
      debugPrint('Error checking reachability: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _messageSubscription?.cancel();
    _contextSubscription?.cancel();
    _reachableCheckTimer?.cancel();
    _isInitialized = false;
    super.dispose();
  }

  /// 处理手表发送的消息
  Future<void> _handleMessage(Map<String, dynamic> message) async {
    debugPrint('Received message from watch: $message');

    final requestType = message['request'] as String?;

    try {
      Map<String, dynamic> response;

      switch (requestType) {
        case 'getChatChannels':
          response = await _getChatChannels();
          break;
        case 'getChatMessages':
          final channelId = message['channelId'] as String?;
          if (channelId == null) {
            throw ArgumentError('channelId is required for getChatMessages');
          }
          response = await _getChatMessages(channelId);
          break;
        default:
          response = {
            'success': false,
            'error': 'Unknown request type: $requestType',
          };
      }

      // 发送回复
      await _watchConnectivity.sendMessage(response);
      debugPrint('Sent response to watch: $response');
    } catch (e) {
      debugPrint('Error handling watch request: $e');
      await _watchConnectivity.sendMessage({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 处理应用上下文更新
  void _handleContextUpdate(Map<String, dynamic> context) {
    debugPrint('Received context update from watch: $context');
  }

  /// 获取所有频道
  Future<Map<String, dynamic>> _getChatChannels() async {
    try {
      final chatPlugin = ChatPlugin.instance;
      if (chatPlugin == null) {
        return {
          'success': false,
          'error': 'Chat plugin not initialized',
        };
      }

      // 使用 channels getter 而不是 getChannels() 方法
      final channels = chatPlugin.channelService.channels;

      // 转换为手表可识别的格式
      final channelData = channels.map((channel) {
        // 计算未读消息数（这里简单实现，可以根据实际需求调整）
        final unreadCount = 0; // 当前版本暂不实现未读计数

        return {
          'id': channel.id,
          'name': channel.title,
          'description': _getChannelDescription(channel),
          'unreadCount': unreadCount,
          'createdAt': null, // Channel 模型中没有 createdAt
          'lastActiveAt': channel.lastMessageTime.toIso8601String(),
        };
      }).toList();

      return {
        'success': true,
        'data': channelData,
      };
    } catch (e) {
      debugPrint('Error getting chat channels: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 获取指定频道的消息
  Future<Map<String, dynamic>> _getChatMessages(String channelId) async {
    try {
      final chatPlugin = ChatPlugin.instance;
      if (chatPlugin == null) {
        return {
          'success': false,
          'error': 'Chat plugin not initialized',
        };
      }

      // 使用 channels getter 并手动查找频道
      final channel = chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == channelId,
        orElse: () => null as Channel,
      );

      if (channel == null) {
        return {
          'success': false,
          'error': 'Channel not found: $channelId',
        };
      }

      final messages = channel.messages;
      // 使用 currentUser getter 而不是 getCurrentUser() 方法
      final currentUser = chatPlugin.userService.currentUser;

      // 转换为手表可识别的格式
      final messageData = messages.map((message) {
        final isMe = message.user.id == currentUser.id;

        return {
          'id': message.id,
          'channelId': channelId,
          'content': message.content,
          'senderId': message.user.id,
          'senderName': message.user.username,
          'timestamp': message.date.toIso8601String(),
          'isMe': isMe,
        };
      }).toList();

      return {
        'success': true,
        'data': messageData,
      };
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 获取频道描述（用于未读消息等）
  String _getChannelDescription(Channel channel) {
    if (channel.lastMessage != null) {
      final content = channel.lastMessage!.content;
      if (content.length > 30) {
        return '${content.substring(0, 30)}...';
      }
      return content;
    }
    return '';
  }

  /// 主动向手表推送数据（可选）
  Future<void> sendUpdateToWatch(Map<String, dynamic> data) async {
    try {
      await _watchConnectivity.sendMessage(data);
      debugPrint('Sent update to watch: $data');
    } catch (e) {
      debugPrint('Error sending update to watch: $e');
    }
  }

  /// 更新应用上下文（用于后台数据同步）
  Future<void> updateApplicationContext(Map<String, dynamic> data) async {
    try {
      await _watchConnectivity.updateApplicationContext(data);
      debugPrint('Updated application context: $data');
    } catch (e) {
      debugPrint('Error updating application context: $e');
    }
  }
}
