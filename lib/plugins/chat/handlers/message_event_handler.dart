import 'dart:developer' as developer;
import 'dart:async';
import '../../../core/event/event.dart';
import '../models/message.dart';
import '../services/channel_service.dart';
import '../chat_plugin.dart';
import '../models/channel.dart';

/// 处理聊天消息相关事件的处理器
class MessageEventHandler {
  late final ChannelService _channelService;
  final eventManager = EventManager.instance;
  final ChatPlugin _plugin;

  MessageEventHandler(this._plugin) {
    _channelService = _plugin.channelService;
    _initialize();
  }

  void _initialize() {
    // 订阅消息更新事件
    eventManager.subscribe('onMessageUpdated', _handleMessageUpdated);
    // 订阅新消息接收事件
    eventManager.subscribe('onMessageReceived', _handleMessageReceived);

    developer.log('消息事件处理器已初始化', name: 'MessageEventHandler');
  }

  /// 处理消息更新事件
  Future<void> _handleMessageUpdated(EventArgs args) async {
    if (args is! Value<Message>) return;
    
    final message = args.value;
    developer.log('处理消息更新: ${message.id}', name: 'MessageEventHandler');
    
    try {
      // 更新当前频道中的消息
      await _channelService.updateMessage(message);
      
      developer.log(
        '消息更新成功: ${message.id}, 内容: ${message.content}',
        name: 'MessageEventHandler'
      );
      
      // ChannelService中已经调用了notifyListeners，这里不需要重复调用
    } catch (e) {
      developer.log(
        '更新消息失败: ${message.id}, 错误: $e',
        name: 'MessageEventHandler',
        error: e
      );
    }
  }

  /// 处理新消息接收事件
  Future<void> _handleMessageReceived(EventArgs args) async {
    if (args is! Value<Message>) return;
    
    final message = args.value;
    developer.log('处理新消息接收: ${message.id}', name: 'MessageEventHandler');
    
    try {
      // 获取当前活跃频道
      final currentChannel = _channelService.currentChannel;
      
      // 如果没有活跃的频道，则抛出异常
      if (currentChannel == null) {
        throw Exception('无法添加消息：没有活跃的频道');
      }
      
      // 创建一个Future<Message>对象，因为addMessage方法需要Future<Message>类型
      final messageFuture = Future<Message>.value(message);
      
      // 将新消息添加到当前频道
      await _channelService.addMessage(currentChannel.id, messageFuture);
      
      developer.log(
        '新消息添加成功: ${message.id}, 内容: ${message.content}',
        name: 'MessageEventHandler'
      );
      
      // ChannelService中已经调用了notifyListeners，这里不需要重复调用
    } catch (e) {
      developer.log(
        '添加新消息失败: ${message.id}, 错误: $e',
        name: 'MessageEventHandler',
        error: e
      );
    }
  }

  /// 清理资源
  void dispose() {
    // 这里可以添加清理代码，如取消事件订阅等
    developer.log('消息事件处理器已释放', name: 'MessageEventHandler');
  }
}