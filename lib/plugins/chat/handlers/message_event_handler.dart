import 'dart:developer' as developer;
import 'dart:async';
import '../../../core/event/event.dart';
import '../models/message.dart';
import '../services/channel_service.dart';
import '../chat_plugin.dart';

// 事件管理器实例
final eventManager = EventManager.instance;

/// 处理聊天消息相关事件的处理器
class MessageEventHandler {
  late final ChannelService _channelService;
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
    // 订阅消息创建事件（用于流式响应前创建气泡）
    eventManager.subscribe('onMessageCreate', _handleMessageCreate);

    developer.log('消息事件处理器已初始化', name: 'MessageEventHandler');
  }

  /// 处理消息更新事件
  Future<void> _handleMessageUpdated(EventArgs args) async {
    if (args is! Values<Message, String>) {
      developer.log(
        '消息更新事件参数类型错误',
        name: 'MessageEventHandler',
        error: 'Expected Values<Message, String>, got ${args.runtimeType}'
      );
      return;
    }
    
    final message = args.value1;
    final channelId = args.value2;
    
    // 检查消息状态
    developer.log(
      '处理消息更新开始: ID=${message.id}, 元数据=${message.metadata}',
      name: 'MessageEventHandler'
    );
    developer.log('处理消息更新: ${message.id}, 内容: ${message.content.substring(0, message.content.length > 20 ? 20 : message.content.length)}...', name: 'MessageEventHandler');
    
    try {
      // 获取当前活跃频道
      final currentChannel = _channelService.currentChannel;
      
      // 如果没有活跃的频道，尝试获取或创建默认频道
      if (currentChannel == null) {
        developer.log(
          '无活跃频道，尝试获取或创建默认频道',
          name: 'MessageEventHandler'
        );
        await _channelService.getOrCreateDefaultChannel();
      }
      
      // 更新消息元数据
      message.metadata ??= {};
      message.metadata!['isThinking'] = false;
      
      // 更新当前频道中的消息，并写入本地文件
      await _channelService.saveMessage(message);
      
      // 强制通知监听器更新UI
      _plugin.notifyListeners();
      
      developer.log(
        '消息状态更新完成，metadata: ${message.metadata}',
        name: 'MessageEventHandler'
      );
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
    if (args is! Value<Message>) {
      developer.log(
        '新消息接收事件参数类型错误',
        name: 'MessageEventHandler',
        error: 'Expected Value<Message>, got ${args.runtimeType}'
      );
      return;
    }
    
    final message = args.value;
    
    // 检查消息状态
    developer.log(
      '处理新消息接收开始: ID=${message.id}, 元数据=${message.metadata}',
      name: 'MessageEventHandler'
    );
    developer.log('处理新消息接收: ${message.id}', name: 'MessageEventHandler');
    
    try {
      // 获取当前活跃频道ID
      final currentChannel = _channelService.currentChannel;
      if (currentChannel == null) {
        developer.log(
          '无活跃频道，尝试获取或创建默认频道',
          name: 'MessageEventHandler'
        );
        final channel = await _channelService.getOrCreateDefaultChannel();
        if (channel == null) {
          throw Exception('无法创建默认频道');
        }
      }
      
      // 将新消息添加到当前活跃频道
      await _channelService.addMessage(_channelService.currentChannel!.id, message);
      
      // 确保UI更新
      _plugin.notifyListeners();
      
      // 手动触发消息更新事件，确保UI更新
      // 使用当前频道ID
      final currentChannelId = _channelService.currentChannel!.id;
      eventManager.broadcast(
        'onMessageUpdated',
        Values<Message, String>(message, currentChannelId),
      );
      
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

  /// 处理消息创建事件（用于流式响应开始前创建聊天气泡）
  Future<void> _handleMessageCreate(EventArgs args) async {
    if (args is! Values<Message, String>) {
      developer.log(
        '消息创建事件参数类型错误',
        name: 'MessageEventHandler',
        error: 'Expected Values<Message, String>, got ${args.runtimeType}'
      );
      return;
    }
    
    final message = args.value1;
    final channelId = args.value2;
    
    // 初始化消息状态
    message.metadata ??= {};
    message.metadata!['isThinking'] = true;
    
    developer.log(
      '处理消息创建开始: ID=${message.id}, 元数据=${message.metadata}',
      name: 'MessageEventHandler'
    );
    developer.log('处理消息创建: ${message.id}', name: 'MessageEventHandler');
    
    try {
      // 将新消息添加到指定频道
      await _channelService.addMessage(channelId, message);
      
      // 手动触发消息更新事件，确保UI更新
      eventManager.broadcast(
        'onMessageUpdated',
        Values<Message, String>(message, channelId),
      );
      
      developer.log(
        '消息气泡创建成功: ${message.id}, 准备接收流式内容',
        name: 'MessageEventHandler'
      );
      
      // ChannelService中已经调用了notifyListeners，这里不需要重复调用
    } catch (e) {
      developer.log(
        '创建消息气泡失败: ${message.id}, 错误: $e',
        name: 'MessageEventHandler',
        error: e
      );
    }
  }

  /// 清理资源
  void dispose() {
    // 取消事件订阅，需要传入对应的处理函数
    eventManager.unsubscribe('onMessageUpdated', _handleMessageUpdated);
    eventManager.unsubscribe('onMessageReceived', _handleMessageReceived);
    eventManager.unsubscribe('onMessageCreate', _handleMessageCreate);
    
    developer.log('消息事件处理器已释放', name: 'MessageEventHandler');
  }
}