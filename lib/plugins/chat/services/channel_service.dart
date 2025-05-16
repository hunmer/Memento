import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/message.dart';
import '../chat_plugin.dart';
import 'user_service.dart';
import '../../../core/event/event.dart';

/// 负责管理频道相关的功能
class ChannelService {
  final ChatPlugin _plugin;
  final List<Channel> _channels = [];
  
  // 获取 UserService 实例
  UserService get _userService => _plugin.userService;
  
  // 当前活跃频道
  Channel? _currentChannel;
  
  // 获取频道列表的getter
  List<Channel> get channels => _channels;
  
  // 获取当前活跃频道的getter
  Channel? get currentChannel => _currentChannel;
  
  // 设置当前活跃频道
  void setCurrentChannel(Channel? channel) {
    _currentChannel = channel;
    _plugin.notifyListeners();
  }

  ChannelService(this._plugin);

  Future<void> initialize() async {
    // 加载默认数据和频道
    await _initializeDefaultData();
    await _loadChannels();
  }

  Future<void> _initializeDefaultData() async {
    // 确保channels数据存在
    final channelsListData = await _plugin.storage.read('chat/channels');
    if (channelsListData.isEmpty) {
      await _plugin.storage.write('chat/channels', {'channels': []});
    }
  }

  Future<void> _loadChannels() async {
    try {
      // 清空现有频道列表，避免重复加载
      _channels.clear();

      // 读取频道列表
      final channelsListData = await _plugin.storage.read('chat/channels');

      if (channelsListData.isNotEmpty &&
          channelsListData.containsKey('channels')) {
        final List<String> channelIds = List<String>.from(
          channelsListData['channels'],
        );

        for (var channelId in channelIds) {
          // 加载频道信息
          final channelData = await _plugin.storage.read(
            'chat/channel/$channelId',
          );
          if (channelData.isEmpty || !channelData.containsKey('channel')) {
            continue;
          }

          // 获取频道数据
          final channelJson = channelData['channel'] as Map<String, dynamic>;

          // 加载消息
          final messagesData = await _plugin.storage.read(
            'chat/messages/$channelId',
          );
          List<Message> messages = [];
          if (messagesData.isNotEmpty && messagesData.containsKey('messages')) {
            final List<dynamic> messagesJson =
                messagesData['messages'] as List<dynamic>;
            // 加载消息并设置channelId
            messages = await Future.wait(
              messagesJson.map((m) async {
                // 创建基础消息对象
                Message message = await Message.fromJson(m as Map<String, dynamic>);
                // 如果消息没有channelId，则设置当前频道的ID
                if (message.channelId == null) {
                  message = await message.copyWith(channelId: channelId);
                }
                return message;
              }),
            );
          }

          // 创建频道对象（草稿信息已包含在channelJson中）
          final channel = Channel.fromJson(
            channelJson,
            messages: messages,
          );

          // 添加到频道列表
          _channels.add(channel);
        }

        // 按优先级和最后消息时间排序频道
        _channels.sort(Channel.compare);
      }
    } catch (e) {
      debugPrint('Error loading channels: $e');
    }
  }

  // 保存频道信息
  Future<void> saveChannel(Channel channel) async {
    // 保存频道信息
    await _plugin.storage.write('chat/channel/${channel.id}', {
      'channel': channel.toJson(),
    });

    // 更新频道列表
    final channelIds = _channels.map((c) => c.id).toList();
    await _plugin.storage.write('chat/channels', {'channels': channelIds});

    // 更新内存中的频道信息
    final index = _channels.indexWhere((c) => c.id == channel.id);
    if (index != -1) {
      _channels[index] = channel;
    } else {
      _channels.add(channel);
    }

    // 重新排序频道列表
    _channels.sort(Channel.compare);
    
    // 通知监听器数据已更新，确保UI刷新
    _plugin.notifyListeners();
  }

  // 更新频道颜色
  Future<void> updateChannelColor(String channelId, Color color) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(backgroundColor: color);
    await saveChannel(updatedChannel);
  }

  // 更新频道元数据
  Future<Channel> updateChannelMetadata(
    String channelId,
    Map<String, dynamic> metadata,
  ) async {
    // 找到并更新频道
    final channel = _channels.firstWhere((c) => c.id == channelId);
    
    // 合并现有元数据和新元数据
    Map<String, dynamic> updatedMetadata = {};
    if (channel.metadata != null) {
      updatedMetadata.addAll(channel.metadata!);
    }
    updatedMetadata.addAll(metadata);
    
    final updatedChannel = channel.copyWith(metadata: updatedMetadata);
    
    // 如果是当前活跃频道，更新 _currentChannel
    if (_currentChannel?.id == channelId) {
      _currentChannel = updatedChannel;
    }
    
    // 保存更新后的频道
    await saveChannel(updatedChannel);
    
    // 确保 UI 得到更新
    _plugin.notifyListeners();
    
    return updatedChannel;
  }

  // 更新频道背景
  Future<Channel> updateChannelBackground(
    String channelId,
    String backgroundPath,
  ) async {
    String normalizedPath = backgroundPath;
    if (normalizedPath.startsWith('./')) {
      String pathWithoutPrefix = normalizedPath.substring(2);
      List<String> components = pathWithoutPrefix.split(RegExp(r'[/\\\\]'));
      normalizedPath = './${components.join('/')}';
    }
    
    // 找到并更新频道
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(backgroundPath: normalizedPath);
    
    // 如果是当前活跃频道，更新 _currentChannel
    if (_currentChannel?.id == channelId) {
      _currentChannel = updatedChannel;
    }
    
    // 保存更新后的频道
    await saveChannel(updatedChannel);
    
    // 确保 UI 得到更新
    _plugin.notifyListeners();
    
    return updatedChannel;
  }

  // 更新频道固定符号
  Future<void> updateChannelFixedSymbol(
    String channelId,
    String? fixedSymbol,
  ) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(fixedSymbol: fixedSymbol);
    await saveChannel(updatedChannel);
  }

  // 保存消息
  Future<void> saveMessages(String channelId, List<Message> messages) async {
    // 立即通知UI更新，确保消息显示
    _plugin.notifyListeners();
    
    try {
      // 保存消息
      final messageJsonList = await Future.wait(
        messages.map((m) => m.toJson()),
      );

      await _plugin.storage.write('chat/messages/$channelId', {
        'messages': messageJsonList,
      });

      // 更新频道的最后一条消息
      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex != -1 && messages.isNotEmpty) {
        // 找出最新的消息
        final latestMessage = messages.reduce(
          (curr, next) => curr.date.isAfter(next.date) ? curr : next,
        );

        // 更新频道的最后一条消息
        _channels[channelIndex].lastMessage = latestMessage;
      }
    } catch (e) {
      debugPrint('Error saving messages: $e');
    } finally {
      // 确保无论成功与否都通知UI更新
      _plugin.notifyListeners();
    }
  }

  /// 保存单条消息
  /// 
  /// 此方法可以保存单条消息而不需要传入整个消息列表。
  /// 使用消息的channelId属性来定位频道，更新消息，然后保存整个频道的消息列表。
  /// 
  /// [message] 要保存的消息对象
  /// 返回 `true` 表示保存成功，`false` 表示未找到消息所属的频道
  Future<bool> saveMessage(Message message) async {
    if (message.channelId == null) {
      debugPrint('无法保存消息：消息缺少channelId属性');
      return false;
    }

    final channelIndex = _channels.indexWhere((c) => c.id == message.channelId);
    if (channelIndex == -1) {
      debugPrint('无法保存消息：找不到ID为 ${message.channelId} 的频道');
      return false;
    }

    // 查找消息在频道中的索引
    final messageIndex = _channels[channelIndex].messages.indexWhere(
      (m) => m.id == message.id
    );

    // 更新或添加消息
    if (messageIndex != -1) {
      _channels[channelIndex].messages[messageIndex] = message;
    } else {
      _channels[channelIndex].messages.add(message);
    }

    // 检查是否需要更新最后一条消息
    if (_channels[channelIndex].lastMessage == null || 
        message.date.isAfter(_channels[channelIndex].lastMessage!.date) ||
        message.id == _channels[channelIndex].lastMessage!.id) {
      _channels[channelIndex].lastMessage = message;
    }

    // 立即通知UI更新，确保消息显示
    _plugin.notifyListeners();

    // 异步保存消息列表
    await saveMessages(message.channelId!, _channels[channelIndex].messages);
    
    // 再次通知以确保存储同步后的状态更新
    _plugin.notifyListeners();
    return true;
  }

  // 保存草稿
  Future<void> saveDraft(String channelId, String draft) async {
    try {
      // 检查频道是否存在
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index == -1) {
        debugPrint('Cannot save draft: Channel $channelId not found');
        return;
      }
      // 更新内存中的频道草稿
      _channels[index].draft = draft.trim().isEmpty ? null : draft;
      // 保存到本地存储
      saveChannel(_channels[index]);

      // 通知监听器数据已更新，以便更新UI
      _plugin.notifyListeners();
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  // 加载草稿
  Future<String?> loadDraft(String channelId) async {
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index != -1) {
        return _channels[index].draft;
      }
      return '';
  }

  // 保存所有频道信息
  Future<void> saveChannels() async {
    for (var channel in _channels) {
      await saveChannel(channel);
    }
  }

  // 删除频道
  Future<void> deleteChannel(String channelId) async {
    try {
      // 删除频道相关数据
      await Future.wait([
        _plugin.storage.delete('chat/channel/$channelId'),
        _plugin.storage.delete('chat/messages/$channelId'),
      ]);

      // 从内存中移除频道
      _channels.removeWhere((channel) => channel.id == channelId);

      // 更新频道列表
      final channelIds = _channels.map((c) => c.id).toList();
      await _plugin.storage.write('chat/channels', {'channels': channelIds});

      // 通知监听器数据已更新
      _plugin.notifyListeners();
    } catch (e) {
      debugPrint('Error deleting channel: $e');
      rethrow; // 重新抛出异常，让调用者知道删除失败
    }
  }

  // 删除频道消息
  Future<void> deleteChannelMessages(String channelId) async {
    try {
      // 删除消息数据
      await _plugin.storage.delete('chat/messages/$channelId');

      // 重新初始化一个空的消息文件
      await _plugin.storage.write('chat/messages/$channelId', {'messages': []});

      // 更新内存中的频道消息
      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex != -1) {
        _channels[channelIndex].messages.clear();
        _channels[channelIndex].lastMessage = null;
      }

      // 通知监听器数据已更新
      _plugin.notifyListeners();

      debugPrint('Successfully cleared messages for channel $channelId');
    } catch (e) {
      debugPrint('Error deleting channel messages: $e');
      rethrow; // 重新抛出异常，让调用者知道删除失败
    }
  }

  // 添加新消息
  Future<void> addMessage(
    String channelId,
    Message messageFuture,
  ) async {
    try {
      // 获取消息对象
      Message message = await messageFuture;
      
      // 如果消息没有channelId，则设置当前频道ID
      if (message.channelId == null) {
        // 创建一个包含channelId的新消息
        message = await message.copyWith(channelId: channelId);
      }
      
      // 找到对应频道
      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex == -1) return;

      // 添加消息到内存中
      _channels[channelIndex].messages.add(message);

      // 更新频道的最后一条消息
      _channels[channelIndex].lastMessage = message;
      
     
      // 异步保存到存储
      await Future.wait([
        saveMessages(channelId, _channels[channelIndex].messages),
        saveDraft(channelId, ''),
      ]);
      
      // 发送消息更新事件
      eventManager.broadcast(
        'onMessageUpdated',
        Value<Message>(message, 'onMessageUpdated'),
      );
      
       // 立即通知UI更新，确保消息显示
      _plugin.notifyListeners();
      
    } catch (e) {
      debugPrint('Error adding message: $e');
      // 确保即使出错也通知UI更新
      _plugin.notifyListeners();
    }
  }

  // 创建新频道
  Future<void> createChannel(Channel channel) async {
    try {
      // 确保所有必要的目录存在
      await Future.wait([
        _plugin.storage.createDirectory('chat/channel'),
        _plugin.storage.createDirectory('chat/messages'),
      ]);

      // 添加到内存中
      _channels.add(channel);

      // 初始化频道的所有必要文件
      await Future.wait([
        // 保存频道基本信息
        _plugin.storage.write('chat/channel/${channel.id}', {
          'channel': channel.toJson(),
        }),
        // 初始化空消息列表
        _plugin.storage.write('chat/messages/${channel.id}', {'messages': []}),
      ]);

      // 更新频道列表
      final channelIds = _channels.map((c) => c.id).toList();
      await _plugin.storage.write('chat/channels', {'channels': channelIds});

      // 重新排序
      _channels.sort(Channel.compare);

      // 通知监听器数据已更新
      _plugin.notifyListeners();
    } catch (e) {
      // 如果创建过程中出现错误，需要清理已创建的内容
      debugPrint('Error creating channel: $e');

      // 从内存中移除
      _channels.removeWhere((c) => c.id == channel.id);

      // 尝试清理已创建的文件
      try {
        await Future.wait([
          _plugin.storage.delete('chat/channel/${channel.id}'),
          _plugin.storage.delete('chat/messages/${channel.id}'),
        ]);
      } catch (cleanupError) {
        debugPrint(
          'Error cleaning up after failed channel creation: $cleanupError',
        );
      }
      rethrow;
    }
  }

  // 更新消息
  /// 更新指定消息的内容
  /// 
  /// 此方法会更新频道中指定ID的消息内容，并触发UI刷新
  Future<void> updateMessage(Message message, {bool persist = true}) async {
    if (message.channelId == null) {
      debugPrint('无法更新消息：消息缺少channelId属性');
      return;
    }

    final channelIndex = _channels.indexWhere((c) => c.id == message.channelId);
    if (channelIndex == -1) {
      debugPrint('无法更新消息：找不到ID为 ${message.channelId} 的频道');
      return;
    }

    // 查找消息在频道中的索引
    final messageIndex = _channels[channelIndex].messages.indexWhere(
      (m) => m.id == message.id
    );

    // 如果找到消息则更新
    if (messageIndex != -1) {
      _channels[channelIndex].messages[messageIndex] = message;

      // 如果这是最后一条消息，也更新频道的lastMessage
      if (_channels[channelIndex].lastMessage?.id == message.id) {
        _channels[channelIndex].lastMessage = message;
      }

      // 根据persist参数决定是否保存到存储
      if (persist) {
        await saveMessages(message.channelId!, _channels[channelIndex].messages);
      }

      // 通过事件系统广播消息更新
      eventManager.broadcast(
        'onMessageUpdated',
        Value<Message>(message, 'onMessageUpdated'),
      );
      // 统一通知UI更新，避免多次触发
      _plugin.notifyListeners();
    } else {
      debugPrint('无法更新消息：在频道 ${message.channelId} 中未找到ID为 ${message.id} 的消息');
    }
  }

  // 获取今日消息数量
  int getTodayMessageCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int count = 0;
    for (var channel in _channels) {
      count +=
          channel.messages.where((msg) {
            final msgDate = DateTime(
              msg.date.year,
              msg.date.month,
              msg.date.day,
            );
            return msgDate.isAtSameMomentAs(today);
          }).length;
    }
    return count;
  }

  // 获取总消息数量
  int getTotalMessageCount() {
    int count = 0;
    for (var channel in _channels) {
      count += channel.messages.length;
    }
    return count;
  }
  
  /// 获取指定频道的所有消息
  /// 
  /// [channelId] 频道ID
  /// 返回频道的消息列表，如果频道不存在则返回null
  Future<List<Message>?> getChannelMessages(String channelId) async {
    try {
      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex == -1) {
        debugPrint('Channel not found: $channelId');
        return null;
      }
      
      return List<Message>.from(_channels[channelIndex].messages);
    } catch (e) {
      debugPrint('Error getting channel messages: $e');
      return null;
    }
  }

  // 根据消息ID获取完整消息
  Message? getMessageById(String messageId) {
    for (var channel in _channels) {
      try {
        return channel.messages.firstWhere(
          (msg) => msg.id == messageId,
        );
      } catch (e) {
        // 在当前频道中没有找到消息，继续查找下一个频道
        continue;
      }
    }
    return null;
  }

  /// 获取指定消息之前的消息
  /// [messageId] 消息ID
  /// [count] 获取的消息数量
  /// [channelId] 频道ID，如果提供则只在指定频道中查找
  /// 返回消息列表，按时间从旧到新排序
  List<Message> getMessagesBefore(String messageId, int count, {String? channelId}) {
    // 如果提供了频道ID，只在指定频道中查找
    if (channelId != null) {
      final channel = _channels.firstWhere(
        (c) => c.id == channelId,
      );
      
      // 如果找不到频道或频道为空，返回空列表
      if (channel.id.isEmpty) {
        debugPrint('警告：找不到ID为 $channelId 的频道');
        return [];
      }
      
      // 找到消息在当前频道的位置
      final index = channel.messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        // 由于消息是倒序存储的（新消息在前），所以我们需要从当前位置往后取消息
        final endIndex = (index + count).clamp(index + 1, channel.messages.length);
        // 返回指定数量的消息，按时间从旧到新排序
        final messages = channel.messages.sublist(index + 1, endIndex).toList();
        messages.sort((a, b) => a.date.compareTo(b.date)); // 确保按时间从旧到新排序
        return messages;
      }
    }
    return [];
  }

  // 加载回复消息
  Future<Message?> loadReplyMessage(String? replyToId) async {
    if (replyToId == null) return null;
    return getMessageById(replyToId);
  }
}
