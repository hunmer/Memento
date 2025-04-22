// import 'dart:io'; // 移除，因为在Web平台不可用
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'l10n/chat_localizations.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'models/channel.dart';
import 'models/message.dart';
import 'models/user.dart';
import '../../models/serialization_helpers.dart';
import 'screens/channel_list/channel_list_screen.dart';
import 'screens/timeline/timeline_screen.dart';
import 'utils/message_operations.dart';

class ChatPlugin extends BasePlugin {
  // 音频播放器实例
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 插件设置
  bool _showAvatarInChat = true; // 提供默认值
  bool _playSoundOnSend = true; // 发送消息时播放提示音

  bool get showAvatarInChat => _showAvatarInChat;
  bool get playSoundOnSend => _playSoundOnSend;

  Future<void> setPlaySoundOnSend(bool value) async {
    _playSoundOnSend = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setShowAvatarInChat(bool value) async {
    _showAvatarInChat = value;
    await _saveSettings();
    notifyListeners();
  }

  // 保存设置
  Future<void> _saveSettings() async {
    await storage.write('chat/settings', {
      'showAvatarInChat': _showAvatarInChat,
      'playSoundOnSend': _playSoundOnSend,
    });
  }

  // 初始化插件设置
  Future<void> _initializeSettings() async {
    try {
      // 从存储中加载设置
      final settings = await storage.read('chat/settings');
      _showAvatarInChat = settings['showAvatarInChat'] ?? true;
      _playSoundOnSend = settings['playSoundOnSend'] ?? true;
    } catch (e) {
      // 如果读取失败，使用默认值
      debugPrint('Error loading chat settings: $e');
      _showAvatarInChat = true;
      _playSoundOnSend = true;
    }
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final l10n = ChatLocalizations.of(context)!;
        return Column(
          children: [
            SwitchListTile(
              title: const Text('在聊天中显示头像'),
              value: _showAvatarInChat,
              onChanged: (bool value) {
                setState(() {
                  setShowAvatarInChat(value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('发送消息播放提示音'),
              value: _playSoundOnSend,
              onChanged: (bool value) {
                setState(() {
                  setPlaySoundOnSend(value);
                });
              },
            ),
            const Divider(),
            super.buildSettingsView(context),
          ],
        );
      },
    );
  }

  static ChatPlugin? _instance;
  static ChatPlugin get instance {
    _instance ??= ChatPlugin();
    return _instance!;
  }

  // 检查插件是否已完全初始化
  bool get isInitialized {
    try {
      // 检查存储管理器和当前用户是否都已初始化
      storage;
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  final List<Channel> _channels = [];
  final List<Function()> _listeners = [];

  // 当前用户
  User? _currentUser;
  User get currentUser {
    if (_currentUser == null) {
      // 创建一个默认用户，避免抛出异常
      _currentUser = User(id: 'default_user', username: 'Default User');
      debugPrint(
        'Warning: Using default user because ChatPlugin is not properly initialized.',
      );
    }
    return _currentUser!;
  }

  // 设置当前用户
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  @override
  String get id => 'chat';

  // 获取频道列表的getter
  List<Channel> get channels => _channels;

  late String _name = 'Chat';
  late String _description = 'A plugin for chatting with other users';

  @override
  String get name => _name;

  @override
  String get version => '1.0.0';

  @override
  String get description => _description;

  @override
  String get author => 'Zhuanz';

  @override
  Future<void> initialize() async {
    // 加载插件设置
    await _initializeSettings();

    // 设置默认用户（如果尚未设置）
    if (_currentUser == null) {
      // 尝试从存储中加载用户信息
      final userData = await storage.read('chat/current_user');
      if (userData.isNotEmpty && userData.containsKey('user')) {
        _currentUser = UserSerializer.fromJson(userData['user']);
      } else {
        // 如果没有存储的用户信息，创建默认用户
        _currentUser = User(id: 'default_user', username: 'Default User');
        // 保存默认用户信息
        await storage.write('chat/current_user', {
          'user': UserSerializer.toJson(_currentUser!),
        });
      }
    }

    // 加载默认数据和频道
    await _initializeDefaultData();
    await _loadChannels();
  }

  // 更新本地化文本
  void updateLocalizedStrings(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
    if (l10n != null) {
      _name = l10n.chatPluginName;
      _description = l10n.chatPluginDescription;
    }
  }

  Future<void> _initializeDefaultData() async {
    // 确保channels数据存在
    final channelsListData = await storage.read('chat/channels');
    if (channelsListData.isEmpty) {
      await storage.write('chat/channels', {'channels': []});
    }
  }

  Future<void> _loadChannels() async {
    try {
      // 清空现有频道列表，避免重复加载
      _channels.clear();

      // 读取频道列表
      final channelsListData = await storage.read('chat/channels');

      if (channelsListData.isNotEmpty &&
          channelsListData.containsKey('channels')) {
        final List<String> channelIds = List<String>.from(
          channelsListData['channels'],
        );

        for (var channelId in channelIds) {
          // 加载频道信息
          final channelData = await storage.read('chat/channel/$channelId');
          if (channelData.isEmpty || !channelData.containsKey('channel')) {
            continue;
          }

          // 加载频道成员
          final channelJson = channelData['channel'] as Map<String, dynamic>;
          final List<dynamic> membersJson =
              channelJson['members'] as List<dynamic>;
          final List<User> members =
              membersJson
                  .map(
                    (m) => UserSerializer.fromJson(m as Map<String, dynamic>),
                  )
                  .toList();

          // 加载消息
          final messagesData = await storage.read('chat/messages/$channelId');
          List<Message> messages = [];

          if (messagesData.isNotEmpty && messagesData.containsKey('messages')) {
            final List<dynamic> messagesJson =
                messagesData['messages'] as List<dynamic>;
            messages =
                messagesJson
                    .map(
                      (m) => MessageSerializer.fromJson(
                        m as Map<String, dynamic>,
                        members,
                        storage,
                      ),
                    )
                    .toList();
          }

          // 加载草稿
          final draftData = await storage.read('chat/draft/$channelId');
          String? draft;
          if (draftData.isNotEmpty && draftData.containsKey('draft')) {
            draft = draftData['draft'] as String;
          }

          // 创建频道对象
          final channel = ChannelSerializer.fromJson(
            channelJson,
            messages: messages,
          );
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
    await storage.write('chat/channel/${channel.id}', {
      'channel': ChannelSerializer.toJson(channel),
    });

    // 更新频道列表
    final channelIds = _channels.map((c) => c.id).toList();
    await storage.write('chat/channels', {'channels': channelIds});

    // 更新内存中的频道信息
    final index = _channels.indexWhere((c) => c.id == channel.id);
    if (index != -1) {
      _channels[index] = channel;
    } else {
      _channels.add(channel);
    }

    // 重新排序频道列表
    _channels.sort(Channel.compare);
  }

  // 更新频道颜色
  Future<void> updateChannelColor(String channelId, Color color) async {
    final channel = _channels.firstWhere((c) => c.id == channelId);
    final updatedChannel = channel.copyWith(backgroundColor: color);
    await saveChannel(updatedChannel);
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
    final messageJsonFutures = messages.map((m) => MessageSerializer.toJson(m));
    final messageJsonList = await Future.wait(messageJsonFutures);

    await storage.write('chat/messages/$channelId', {
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
      notifyListeners();
    }
  }

  // 保存草稿
  Future<void> saveDraft(String channelId, String draft) async {
    try {
      // 确保目录存在
      await storage.createDirectory('chat/draft');

      // 检查频道是否存在
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index == -1) {
        debugPrint('Cannot save draft: Channel $channelId not found');
        return;
      }

      // 检查草稿文件是否存在
      final draftExists = await storage.fileExists('chat/draft/$channelId');

      if (draft.trim().isEmpty) {
        // 如果草稿为空且文件存在，删除草稿文件
        if (draftExists) {
          await storage.delete('chat/draft/$channelId');
        }
        // 如果草稿为空且文件不存在，不需要任何操作
      } else {
        // 保存草稿
        await storage.write('chat/draft/$channelId', {'draft': draft});
      }

      // 更新内存中的频道草稿
      _channels[index].draft = draft.trim().isEmpty ? null : draft;

      // 通知监听器数据已更新，以便更新UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  // 加载草稿
  Future<String?> loadDraft(String channelId) async {
    if (!isInitialized) {
      debugPrint('ChatPlugin is not initialized yet. Cannot load draft.');
      return null;
    }

    try {
      // 先检查文件是否存在
      final fileExists = await storage.fileExists('chat/draft/$channelId');
      if (!fileExists) {
        // 如果文件不存在，确保目录存在并创建空草稿
        await storage.createDirectory('chat/draft');
        await storage.write('chat/draft/$channelId', {'draft': ''});
        return null;
      }

      // 读取草稿数据
      final draftData = await storage.read('chat/draft/$channelId');
      if (draftData.isNotEmpty && draftData.containsKey('draft')) {
        final draft = draftData['draft'] as String;
        return draft.isEmpty ? null : draft;
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
      // 出错时创建空草稿
      try {
        await storage.createDirectory('chat/draft');
        await storage.write('chat/draft/$channelId', {'draft': ''});
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
        storage.delete('chat/channel/$channelId'),
        storage.delete('chat/messages/$channelId'),
        storage.delete('chat/draft/$channelId'),
      ]);

      // 从内存中移除频道
      _channels.removeWhere((channel) => channel.id == channelId);

      // 更新频道列表
      final channelIds = _channels.map((c) => c.id).toList();
      await storage.write('chat/channels', {'channels': channelIds});

      // 通知监听器数据已更新
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting channel: $e');
      rethrow; // 重新抛出异常，让调用者知道删除失败
    }
  }

  // 删除频道消息
  Future<void> deleteChannelMessages(String channelId) async {
    try {
      // 删除消息数据
      await storage.delete('chat/messages/$channelId');

      // 重新初始化一个空的消息文件
      await storage.write('chat/messages/$channelId', {'messages': []});

      // 更新内存中的频道消息
      final channelIndex = _channels.indexWhere((c) => c.id == channelId);
      if (channelIndex != -1) {
        _channels[channelIndex].messages.clear();
        _channels[channelIndex].lastMessage = null;
      }

      // 通知监听器数据已更新
      notifyListeners();

      debugPrint('Successfully cleared messages for channel $channelId');
    } catch (e) {
      debugPrint('Error deleting channel messages: $e');
      rethrow; // 重新抛出异常，让调用者知道删除失败
    }
  }

  // 检查是否应该播放消息提示音
  bool shouldPlayMessageSound() {
    return _playSoundOnSend;
  }

  // 添加新消息
  Future<void> addMessage(String channelId, Message message) async {
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
    notifyListeners();
  }

  // 创建新频道
  Future<void> createChannel(Channel channel) async {
    try {
      // 确保所有必要的目录存在
      await Future.wait([
        storage.createDirectory('chat/channel'),
        storage.createDirectory('chat/messages'),
        storage.createDirectory('chat/draft'),
      ]);

      // 添加到内存中
      _channels.add(channel);

      // 初始化频道的所有必要文件
      await Future.wait([
        // 保存频道基本信息
        storage.write('chat/channel/${channel.id}', {
          'channel': ChannelSerializer.toJson(channel),
        }),
        // 初始化空消息列表
        storage.write('chat/messages/${channel.id}', {'messages': []}),
        // 初始化空草稿
        storage.write('chat/draft/${channel.id}', {'draft': ''}),
      ]);

      // 更新频道列表
      final channelIds = _channels.map((c) => c.id).toList();
      await storage.write('chat/channels', {'channels': channelIds});

      // 重新排序
      _channels.sort(Channel.compare);

      // 通知监听器数据已更新
      notifyListeners();
    } catch (e) {
      // 如果创建过程中出现错误，需要清理已创建的内容
      debugPrint('Error creating channel: $e');

      // 从内存中移除
      _channels.removeWhere((c) => c.id == channel.id);

      // 尝试清理已创建的文件
      try {
        await Future.wait([
          storage.delete('chat/channel/${channel.id}'),
          storage.delete('chat/messages/${channel.id}'),
          storage.delete('chat/draft/${channel.id}'),
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

  @override
  Widget buildMainView(BuildContext context) {
    // 更新本地化文本
    updateLocalizedStrings(context);

    final l10n = ChatLocalizations.of(context);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: TabBarView(
          children: [
            // 频道列表标签页
            ChannelListScreen(channels: _channels, chatPlugin: this),
            // 时间线标签页
            TimelineScreen(chatPlugin: this),
          ],
        ),
        bottomNavigationBar: TabBar(
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.chat_bubble_outline),
              text: l10n?.channelsTab ?? 'Channels',
            ),
            Tab(
              icon: const Icon(Icons.timeline),
              text: l10n?.timelineTab ?? 'Timeline',
            ),
          ],
        ),
      ),
    );
  }

  /// 注册插件到应用
  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 设置默认名称和描述（以防在initialize前使用）
    _name = 'Chat';
    _description = 'A plugin for chatting with other users';

    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'notifications': true, 'theme': 'light'},
    });
  }
}
