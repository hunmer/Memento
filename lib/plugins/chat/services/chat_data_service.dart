import 'dart:math';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/core/event/event.dart' as memento_event;
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/chat/services/widget_service.dart';
import 'package:Memento/plugins/chat/sample_data.dart';

/// 聊天数据服务
///
/// 职责：统一管理频道和消息的所有数据操作
/// - 频道的 CRUD 操作
/// - 消息的 CRUD 操作
/// - 数据持久化与缓存
/// - 事件广播
class ChatDataService {
  final ChatPlugin _plugin;
  final List<Channel> _channels = [];

  // 当前活跃频道
  Channel? _currentChannel;

  // ==================== Getters ====================

  List<Channel> get channels => _channels;
  Channel? get currentChannel => _currentChannel;

  ChatDataService(this._plugin);

  // ==================== 初始化 ====================

  Future<void> initialize() async {
    await _initializeDefaultData();
    await _loadChannels();
  }

  Future<void> _initializeDefaultData() async {
    final channelsListData = await _plugin.storage.read('chat/channels');
    if (channelsListData.isEmpty) {
      debugPrint('Chat插件: 首次初始化，正在加载示例数据...');
      await _loadSampleData();
    }
  }

  Future<void> _loadSampleData() async {
    try {
      final sampleData = getSampleChannelsData();
      final sampleMessages = getSampleMessagesData();

      await Future.wait([
        _plugin.storage.createDirectory('chat/channel'),
        _plugin.storage.createDirectory('chat/messages'),
      ]);

      final channelIds = (sampleData['channels'] as List)
          .map((channel) => channel['id'] as String)
          .toList();
      await _plugin.storage.write('chat/channels', {'channels': channelIds});

      for (var channelJson in sampleData['channels'] as List) {
        final channelId = channelJson['id'] as String;

        await _plugin.storage.write('chat/channel/$channelId', {
          'channel': channelJson,
        });

        final messages = sampleMessages[channelId];
        if (messages != null && messages.isNotEmpty) {
          await _plugin.storage.write('chat/messages/$channelId', {
            'messages': messages,
          });
          debugPrint('Chat插件: 已加载频道 "${channelJson['name']}" 的 ${messages.length} 条消息');
        } else {
          await _plugin.storage.write('chat/messages/$channelId', {
            'messages': [],
          });
        }
      }

      if (sampleData.containsKey('settings')) {
        await _plugin.storage.write('chat/settings', sampleData['settings']);
      }

      debugPrint('Chat插件: 示例数据加载完成！共加载 ${channelIds.length} 个频道');
    } catch (e) {
      debugPrint('Chat插件: 加载示例数据失败: $e');
      await _createDefaultChannel();
    }
  }

  Future<void> _createDefaultChannel() async {
    try {
      final defaultChannel = {
        'id': 'default',
        'name': '默认频道',
        'description': '系统的默认频道',
        'color': Colors.blue.value,
        'icon': 'chat',
        'isDefault': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
        'messageCount': 0,
        'unreadCount': 0
      };

      await _plugin.storage.write('chat/channels', {'channels': ['default']});
      await _plugin.storage.write('chat/channel/default', {
        'channel': defaultChannel,
      });
      await _plugin.storage.write('chat/messages/default', {
        'messages': [],
      });

      debugPrint('Chat插件: 已创建默认频道');
    } catch (e) {
      debugPrint('Chat插件: 创建默认频道失败: $e');
    }
  }

  Future<void> _loadChannels() async {
    try {
      _channels.clear();

      final channelsListData = await _plugin.storage.read('chat/channels');

      if (channelsListData.isNotEmpty &&
          channelsListData.containsKey('channels')) {
        final List<String> channelIds = List<String>.from(
          channelsListData['channels'],
        );

        for (var channelId in channelIds) {
          final channelData = await _plugin.storage.read(
            'chat/channel/$channelId',
          );
          if (channelData.isEmpty || !channelData.containsKey('channel')) {
            continue;
          }

          final channelJson = channelData['channel'] as Map<String, dynamic>;

          final messagesData = await _plugin.storage.read(
            'chat/messages/$channelId',
          );
          List<Message> messages = [];
          if (messagesData.isNotEmpty && messagesData.containsKey('messages')) {
            final List<dynamic> messagesJson =
                messagesData['messages'] as List<dynamic>;
            messages = await Future.wait(
              messagesJson.map((m) async {
                Message message = await Message.fromJson(
                  m as Map<String, dynamic>,
                );
                if (message.channelId == null) {
                  message = await message.copyWith(channelId: channelId);
                }
                return message;
              }),
            );
          }

          final channel = Channel.fromJson(channelJson, messages: messages);
          _channels.add(channel);
        }

        _channels.sort(Channel.compare);
      }
    } catch (e) {
      debugPrint('Error loading channels: $e');
    }
  }

  // ==================== 频道操作 ====================

  void setCurrentChannel(Channel? channel) {
    _currentChannel = channel;
    _plugin.refresh();
  }

  Future<void> createChannel(Channel channel) async {
    try {
      await Future.wait([
        _plugin.storage.createDirectory('chat/channel'),
        _plugin.storage.createDirectory('chat/messages'),
      ]);

      _channels.add(channel);

      await Future.wait([
        _plugin.storage.write('chat/channel/${channel.id}', {
          'channel': channel.toJson(),
        }),
        _plugin.storage.write('chat/messages/${channel.id}', {'messages': []}),
      ]);

      final channelIds = _channels.map((c) => c.id).toList();
      await _plugin.storage.write('chat/channels', {'channels': channelIds});

      _channels.sort(Channel.compare);
      _plugin.refresh();
    } catch (e) {
      debugPrint('Error creating channel: $e');
      _channels.removeWhere((c) => c.id == channel.id);

      try {
        await Future.wait([
          _plugin.storage.delete('chat/channel/${channel.id}'),
          _plugin.storage.delete('chat/messages/${channel.id}'),
        ]);
      } catch (cleanupError) {
        debugPrint('Error cleaning up after failed channel creation: $cleanupError');
      }
      rethrow;
    }
  }

  Future<void> saveChannel(Channel channel) async {
    await _plugin.storage.write('chat/channel/${channel.id}', {
      'channel': channel.toJson(),
    });

    final channelIds = _channels.map((c) => c.id).toList();
    await _plugin.storage.write('chat/channels', {'channels': channelIds});

    final index = _channels.indexWhere((c) => c.id == channel.id);
    if (index != -1) {
      _channels[index] = channel;
    } else {
      _channels.add(channel);
    }

    _channels.sort(Channel.compare);
    _plugin.refresh();
    await _syncWidget();
  }

  Future<void> deleteChannel(String channelId) async {
    try {
      await Future.wait([
        _plugin.storage.delete('chat/channel/$channelId'),
        _plugin.storage.delete('chat/messages/$channelId'),
      ]);

      _channels.removeWhere((channel) => channel.id == channelId);

      final channelIds = _channels.map((c) => c.id).toList();
      await _plugin.storage.write('chat/channels', {'channels': channelIds});

      _plugin.refresh();
      await _syncWidget();
    } catch (e) {
      debugPrint('Error deleting channel: $e');
      rethrow;
    }
  }

  Future<void> deleteChannelMessages(String channelId) async {
    try {
      await _plugin.storage.delete('chat/messages/$channelId');
      await _plugin.storage.write('chat/messages/$channelId', {'messages': []});

      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex != -1) {
        _channels[channelIndex].messages.clear();
        _channels[channelIndex].lastMessage = null;
      }

      _plugin.refresh();
      debugPrint('Successfully cleared messages for channel $channelId');
    } catch (e) {
      debugPrint('Error deleting channel messages: $e');
      rethrow;
    }
  }

  Future<void> updateChannelColor(String channelId, Color color) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(backgroundColor: color);
    await saveChannel(updatedChannel);
  }

  Future<Channel> updateChannelMetadata(
    String channelId,
    Map<String, dynamic> metadata,
  ) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);

    Map<String, dynamic> updatedMetadata = {};
    if (channel.metadata != null) {
      updatedMetadata.addAll(channel.metadata!);
    }
    updatedMetadata.addAll(metadata);

    final updatedChannel = channel.copyWith(metadata: updatedMetadata);

    if (_currentChannel?.id == channelId) {
      _currentChannel = updatedChannel;
    }

    await saveChannel(updatedChannel);
    _plugin.refresh();

    return updatedChannel;
  }

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

    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(backgroundPath: normalizedPath);

    if (_currentChannel?.id == channelId) {
      _currentChannel = updatedChannel;
    }

    await saveChannel(updatedChannel);
    _plugin.refresh();

    return updatedChannel;
  }

  Future<void> updateChannelFixedSymbol(
    String channelId,
    String? fixedSymbol,
  ) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(fixedSymbol: fixedSymbol);
    await saveChannel(updatedChannel);
  }

  Future<void> saveDraft(String channelId, String draft) async {
    try {
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index == -1) {
        debugPrint('Cannot save draft: Channel $channelId not found');
        return;
      }
      _channels[index].draft = draft.trim().isEmpty ? null : draft;
      saveChannel(_channels[index]);
      _plugin.refresh();
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> saveChannels() async {
    for (var channel in _channels) {
      await saveChannel(channel);
    }
  }

  Future<String?> loadDraft(String channelId) async {
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      return _channels[index].draft;
    }
    return '';
  }

  // ==================== 消息操作 ====================

  Future<void> saveMessages(String channelId, List<Message> messages) async {
    _plugin.refresh();

    try {
      final messageJsonList = await Future.wait(
        messages.map((m) => m.toJson()),
      );

      await _plugin.storage.write('chat/messages/$channelId', {
        'messages': messageJsonList,
      });

      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex != -1 && messages.isNotEmpty) {
        final latestMessage = messages.reduce(
          (curr, next) => curr.date.isAfter(next.date) ? curr : next,
        );
        _channels[channelIndex].lastMessage = latestMessage;
      }
    } catch (e) {
      debugPrint('Error saving messages: $e');
    } finally {
      _plugin.refresh();
    }
  }

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

    final messageIndex = _channels[channelIndex].messages.indexWhere(
      (m) => m.id == message.id,
    );

    if (messageIndex != -1) {
      _channels[channelIndex].messages[messageIndex] = message;
    } else {
      _channels[channelIndex].messages.add(message);
    }

    if (_channels[channelIndex].lastMessage == null ||
        message.date.isAfter(_channels[channelIndex].lastMessage!.date) ||
        message.id == _channels[channelIndex].lastMessage!.id) {
      _channels[channelIndex].lastMessage = message;
    }

    _plugin.refresh();
    await saveMessages(message.channelId!, _channels[channelIndex].messages);
    _plugin.refresh();
    ChatWidgetService.updateWidget();

    return true;
  }

  Future<void> addMessage(String channelId, Message messageFuture) async {
    try {
      Message message = messageFuture;

      if (message.channelId == null) {
        message = await message.copyWith(channelId: channelId);
      }

      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex == -1) return;

      _channels[channelIndex].messages.add(message);
      _channels[channelIndex].lastMessage = message;

      await Future.wait([
        saveMessages(channelId, _channels[channelIndex].messages),
        saveDraft(channelId, ''),
      ]);

      memento_event.EventManager.instance.broadcast(
        'onMessageUpdated',
        memento_event.Value<Message>(message, 'onMessageUpdated'),
      );

      _plugin.refresh();
    } catch (e) {
      debugPrint('Error adding message: $e');
      _plugin.refresh();
    }
  }

  Future<bool> deleteMessage(Message message) async {
    if (message.channelId == null) {
      debugPrint('无法删除消息：消息缺少channelId属性');
      return false;
    }

    final channelIndex = _channels.indexWhere((c) => c.id == message.channelId);
    if (channelIndex == -1) {
      debugPrint('无法删除消息：找不到ID为 ${message.channelId} 的频道');
      return false;
    }

    final originalLength = _channels[channelIndex].messages.length;
    _channels[channelIndex].messages.removeWhere((m) => m.id == message.id);

    if (_channels[channelIndex].messages.length == originalLength) {
      debugPrint('无法删除消息：在频道 ${message.channelId} 中未找到ID为 ${message.id} 的消息');
      return false;
    }

    if (_channels[channelIndex].lastMessage?.id == message.id) {
      if (_channels[channelIndex].messages.isNotEmpty) {
        _channels[channelIndex].lastMessage = _channels[channelIndex].messages
            .reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);
      } else {
        _channels[channelIndex].lastMessage = null;
      }
    }

    await saveMessages(message.channelId!, _channels[channelIndex].messages);
    _plugin.refresh();
    return true;
  }

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

    final messageIndex = _channels[channelIndex].messages.indexWhere(
      (m) => m.id == message.id,
    );

    if (messageIndex != -1) {
      _channels[channelIndex].messages[messageIndex] = message;

      if (_channels[channelIndex].lastMessage?.id == message.id) {
        _channels[channelIndex].lastMessage = message;
      }

      if (persist) {
        await saveMessages(
          message.channelId!,
          _channels[channelIndex].messages,
        );
      }

      memento_event.EventManager.instance.broadcast(
        'onMessageUpdated',
        memento_event.Value<Message>(message, 'onMessageUpdated'),
      );
      _plugin.refresh();
      ChatWidgetService.updateWidget();
    } else {
      debugPrint('无法更新消息：在频道 ${message.channelId} 中未找到ID为 ${message.id} 的消息');
    }
  }

  // ==================== 查询操作 ====================

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

  Message? getMessageById(String messageId) {
    for (var channel in _channels) {
      try {
        return channel.messages.firstWhere((msg) => msg.id == messageId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<List<Message>> getAllMessages() async {
    List<Message> allMessages = [];
    for (var channel in _channels) {
      allMessages.addAll(channel.messages);
    }
    allMessages.sort((a, b) => b.date.compareTo(a.date));
    return allMessages;
  }

  List<Message> getMessagesBefore(
    String messageId,
    int count, {
    String? channelId,
  }) {
    if (channelId != null) {
      final channel = _channels.firstWhere((c) => c.id == channelId);

      final index = channel.messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        final index1 = index;
        final index2 = index1 - count;
        final startIndex = min(index1, index2);
        final endIndex = max(index1, index2);
        final messages =
            channel.messages
                .sublist(
                  max(0, startIndex),
                  min(endIndex, channel.messages.length - 1),
                )
                .toList();
        messages.sort((a, b) => a.date.compareTo(b.date));
        return messages;
      }
    }
    return [];
  }

  Future<Message?> loadReplyMessage(String? replyToId) async {
    if (replyToId == null) return null;
    return getMessageById(replyToId);
  }

  // ==================== 统计操作 ====================

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

  int getTotalMessageCount() {
    int count = 0;
    for (var channel in _channels) {
      count += channel.messages.length;
    }
    return count;
  }

  // ==================== 私有辅助方法 ====================

  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncChat();
  }
}
