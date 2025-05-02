import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../chat_plugin.dart';

/// 负责管理频道相关的功能
class ChannelService {
  final ChatPlugin _plugin;
  final List<Channel> _channels = [];
  
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

          // 加载频道成员
          final channelJson = channelData['channel'] as Map<String, dynamic>;
          final List<dynamic> membersJson =
              channelJson['members'] as List<dynamic>;
          final List<User> members =
              membersJson
                  .map((m) => User.fromJson(m as Map<String, dynamic>))
                  .toList();

          // 加载消息
          final messagesData = await _plugin.storage.read(
            'chat/messages/$channelId',
          );
          List<Message> messages = [];

          if (messagesData.isNotEmpty && messagesData.containsKey('messages')) {
            final List<dynamic> messagesJson =
                messagesData['messages'] as List<dynamic>;
            messages = await Future.wait(
              messagesJson.map(
                (m) => Message.fromJson(m as Map<String, dynamic>, members),
              ),
            );
          }

          // 加载草稿
          final draftData = await _plugin.storage.read('chat/draft/$channelId');
          String? draft;
          if (draftData.isNotEmpty && draftData.containsKey('draft')) {
            draft = draftData['draft'] as String;
          }

          // 创建频道对象
          final channel = Channel.fromJson(channelJson, messages: messages);
          channel.draft = draft;
          _channels.add(channel);
        }

        // 按优先级和最后消息时间排序
        _channels.sort(Channel.compare);
        print('Loaded ${_channels.length} channels.');
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
    // 保存消息
    final messageJsonFutures = messages.map((m) => m.toJson());
    final messageJsonList = await Future.wait(messageJsonFutures);

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

      // 通知监听器数据已更新
      _plugin.notifyListeners();
    }
  }

  // 保存草稿
  Future<void> saveDraft(String channelId, String draft) async {
    try {
      // 确保目录存在
      await _plugin.storage.createDirectory('chat/draft');

      // 检查频道是否存在
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index == -1) {
        debugPrint('Cannot save draft: Channel $channelId not found');
        return;
      }

      // 检查草稿文件是否存在
      final draftExists = await _plugin.storage.fileExists(
        'chat/draft/$channelId',
      );

      if (draft.trim().isEmpty) {
        // 如果草稿为空且文件存在，删除草稿文件
        if (draftExists) {
          await _plugin.storage.delete('chat/draft/$channelId');
        }
        // 如果草稿为空且文件不存在，不需要任何操作
      } else {
        // 保存草稿
        await _plugin.storage.write('chat/draft/$channelId', {'draft': draft});
      }

      // 更新内存中的频道草稿
      _channels[index].draft = draft.trim().isEmpty ? null : draft;

      // 通知监听器数据已更新，以便更新UI
      _plugin.notifyListeners();
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  // 加载草稿
  Future<String?> loadDraft(String channelId) async {
    if (!_plugin.isInitialized) {
      debugPrint('ChatPlugin is not initialized yet. Cannot load draft.');
      return null;
    }

    try {
      // 先检查文件是否存在
      final fileExists = await _plugin.storage.fileExists(
        'chat/draft/$channelId',
      );
      if (!fileExists) {
        // 如果文件不存在，确保目录存在并创建空草稿
        await _plugin.storage.createDirectory('chat/draft');
        await _plugin.storage.write('chat/draft/$channelId', {'draft': ''});
        return null;
      }

      // 读取草稿数据
      final draftData = await _plugin.storage.read('chat/draft/$channelId');
      if (draftData.isNotEmpty && draftData.containsKey('draft')) {
        final draft = draftData['draft'] as String;
        return draft.isEmpty ? null : draft;
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
      // 出错时创建空草稿
      try {
        await _plugin.storage.createDirectory('chat/draft');
        await _plugin.storage.write('chat/draft/$channelId', {'draft': ''});
      } catch (e2) {
        debugPrint('Error creating empty draft: $e2');
      }
    }

    return null;
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
        _plugin.storage.delete('chat/draft/$channelId'),
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
    Future<Message> messageFuture,
  ) async {
    final message = await messageFuture;
    // 找到对应频道
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex == -1) return;

    // 添加消息到内存中
    _channels[channelIndex].messages.add(message);

    // 更新频道的最后一条消息
    _channels[channelIndex].lastMessage = message;

    // 保存到存储
    await saveMessages(channelId, _channels[channelIndex].messages);

    // 通知监听器数据已更新
    _plugin.notifyListeners();
  }

  // 创建新频道
  Future<void> createChannel(Channel channel) async {
    try {
      // 确保所有必要的目录存在
      await Future.wait([
        _plugin.storage.createDirectory('chat/channel'),
        _plugin.storage.createDirectory('chat/messages'),
        _plugin.storage.createDirectory('chat/draft'),
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
        // 初始化空草稿
        _plugin.storage.write('chat/draft/${channel.id}', {'draft': ''}),
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
          _plugin.storage.delete('chat/draft/${channel.id}'),
        ]);
      } catch (cleanupError) {
        debugPrint(
          'Error cleaning up after failed channel creation: $cleanupError',
        );
      }

      // 重新抛出异常
      rethrow;
    }
  }

  // 更新消息
  /// 更新指定消息的内容
  /// 
  /// 此方法会更新频道中指定ID的消息内容，并触发UI刷新
  Future<void> updateMessage(Message message, {bool persist = true}) async {
    bool messageFound = false;
    
    // 遍历所有频道查找消息
    for (final channel in _channels) {
      final messageIndex = channel.messages.indexWhere((m) => m.id == message.id);
      
      if (messageIndex != -1) {
        // 找到消息，更新它
        channel.messages[messageIndex] = message;
        
        // 如果这是最后一条消息，也更新频道的lastMessage
        if (channel.lastMessage?.id == message.id) {
          channel.lastMessage = message;
        }
        
        messageFound = true;
        
        // 根据persist参数决定是否保存到存储
        if (persist) {
          try {
            await saveMessages(channel.id, channel.messages);
          } catch (error) {
            debugPrint('保存消息失败: $error');
          }
        }
      }
    }
    
    if (messageFound) {
      // 统一通知UI更新，避免多次触发
      _plugin.notifyListeners();
    } else {
      debugPrint('无法更新消息：未找到ID为 ${message.id} 的消息');
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

  // 加载回复消息
  Future<Message?> loadReplyMessage(String? replyToId) async {
    if (replyToId == null) return null;
    return getMessageById(replyToId);
  }

  /// 获取或创建默认频道
  /// 如果没有频道或当前没有活跃频道，则创建一个默认频道
  Future<Channel?> getOrCreateDefaultChannel() async {
    try {
      // 如果已有活跃频道，直接返回
      if (_currentChannel != null) {
        return _currentChannel;
      }
      
      // 如果有频道但没有活跃频道，设置第一个为活跃频道
      if (_channels.isNotEmpty) {
        _currentChannel = _channels.first;
        _plugin.notifyListeners();
        return _currentChannel;
      }
      
      // 如果没有任何频道，创建默认频道
      final defaultUser = User(
        id: 'user',
        username: '用户',
      );
      
      final defaultChannel = Channel(
        id: 'default_${DateTime.now().millisecondsSinceEpoch}',
        title: '默认对话',
        icon: Icons.chat_bubble_outline,
        members: [defaultUser],
        messages: [],
        priority: 0,
      );
      
      // 创建频道
      await createChannel(defaultChannel);
      
      // 设置为当前活跃频道
      _currentChannel = defaultChannel;
      _plugin.notifyListeners();
      
      debugPrint('已创建默认频道: ${defaultChannel.id}');
      return defaultChannel;
    } catch (e) {
      debugPrint('创建默认频道失败: $e');
      return null;
    }
  }
}
