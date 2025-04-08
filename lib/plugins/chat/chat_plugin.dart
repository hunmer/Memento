// import 'dart:io'; // 移除，因为在Web平台不可用
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/chat_localizations.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../models/channel.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../models/serialization_helpers.dart';
import '../../screens/channel_list_screen.dart';

class ChatPlugin extends BasePlugin {
  // 新增：插件设置
  late bool _showAvatarInChannelList;

  bool get showAvatarInChannelList => _showAvatarInChannelList;

  // 新增：设置是否在聊天列表显示自己的头像
  Future<void> setShowAvatarInChannelList(bool value) async {
    _showAvatarInChannelList = value;
    // 保存设置到本地存储
    await storage.write('chat/settings', {'showAvatarInChannelList': value});
  }

  // 初始化插件设置
  Future<void> _initializeSettings() async {
    // 从存储中加载设置
    final settings = await storage.read('chat/settings');
    _showAvatarInChannelList = settings['showAvatarInChannelList'] ?? true;
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final l10n = ChatLocalizations.of(context)!;
        return Column(
          children: [
            SwitchListTile(
              title: Text(l10n.showAvatarInChannelList),
              value: _showAvatarInChannelList,
              onChanged: (bool value) {
                setState(() {
                  setShowAvatarInChannelList(value);
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

  final List<Channel> _channels = [];
  final List<Function()> _listeners = [];

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

  late String _name =  'Chat';
  late String _description =  'A plugin for chatting with other users';
  
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

    // 加载默认数据和频道
    await _initializeDefaultData();
    await _loadChannels();
  }

  // 更新本地化文本
  void updateLocalizedStrings(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
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
    await storage.write('chat/messages/$channelId', {
      'messages': messages.map((m) => MessageSerializer.toJson(m)).toList(),
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
    // 保存草稿
    await storage.write('chat/draft/$channelId', {'draft': draft});

    // 更新内存中的频道草稿
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      _channels[index].draft = draft;

      // 通知监听器数据已更新，以便更新UI
      notifyListeners();
    }
  }

  // 加载草稿
  Future<String?> loadDraft(String channelId) async {
    final draftData = await storage.read('chat/draft/$channelId');
    if (draftData.isNotEmpty && draftData.containsKey('draft')) {
      return draftData['draft'] as String;
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
      await storage.delete('chat/channel/$channelId');
      await storage.delete('chat/messages/$channelId');
      await storage.delete('chat/draft/$channelId');

      // 从内存中移除频道
      _channels.removeWhere((channel) => channel.id == channelId);

      // 更新频道列表
      final channelIds = _channels.map((c) => c.id).toList();
      await storage.write('chat/channels', {'channels': channelIds});
    } catch (e) {
      debugPrint('Error deleting channel: $e');
    }
  }

  // 删除频道消息
  Future<void> deleteChannelMessages(String channelId) async {
    try {
      // 删除消息数据
      await storage.delete('chat/messages/$channelId');
    } catch (e) {
      debugPrint('Error deleting channel messages: $e');
    }
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
    // 添加到内存中
    _channels.add(channel);

    // 保存频道信息（saveChannel方法已包含更新channels.json的逻辑）
    await saveChannel(channel);

    // 保存空消息列表
    await saveMessages(channel.id, []);

    // 重新排序
    _channels.sort(Channel.compare);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ChannelListScreen(channels: _channels, chatPlugin: this);
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
