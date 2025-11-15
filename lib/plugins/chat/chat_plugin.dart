import 'dart:convert';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'services/channel_service.dart';
import 'services/message_service.dart';
import 'services/settings_service.dart';
import 'services/ui_service.dart';
import 'services/user_service.dart';
import 'controls/prompt_controller.dart';

class ChatMainView extends StatefulWidget {
  const ChatMainView({super.key});
  @override
  State<ChatMainView> createState() => _ChatMainViewState();
}

class _ChatMainViewState extends State<ChatMainView> {
  late ChatPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin;
  }

  @override
  Widget build(BuildContext context) {
    return _plugin.uiService.buildMainView(context);
  }
}

class ChatPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  static ChatPlugin? _instance;

  static ChatPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (_instance == null) {
        throw StateError('ChatPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  // Services
  late final ChannelService channelService;
  late final MessageService messageService;
  late final SettingsService settingsService;
  late final UIService uiService;
  late final UserService userService;

  // Prompt controller
  late final ChatPromptController _promptController;
  @override
  String get id => 'chat';

  @override
  Color get color => Colors.indigoAccent;

  @override
  IconData get icon => Icons.chat_bubble;

  @override
  Future<void> initialize() async {
    // Initialize services
    settingsService = SettingsService(this);
    userService = UserService(this);
    channelService = ChannelService(this);
    messageService = MessageService(this);
    uiService = UIService(settingsService, userService, this);

    // Initialize all services
    await settingsService.initialize();
    await userService.initialize();
    await channelService.initialize();
    await messageService.initialize();
    await uiService.initialize();

    // Initialize prompt controller
    _promptController = ChatPromptController(this);
    _promptController.initialize();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return ChatLocalizations.of(context).name;
  }

  /// 根据消息ID获取消息
  /// 代理到 channelService.getMessageById
  Future<Message?> getMessage(String messageId) async {
    return channelService.getMessageById(messageId);
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            uiService.buildUserProfileCard(context, setState),
            const SizedBox(height: 16),
            uiService.buildChatSettingsCard(context, setState),
            const Divider(),
            super.buildSettingsView(context),
          ],
        );
      },
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ChatMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    return uiService.buildCardView(context);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 测试API（同步）
      'testSync': _jsTestSync,

      // 频道相关
      'getChannels': _jsGetChannels,
      'createChannel': _jsCreateChannel,
      'deleteChannel': _jsDeleteChannel,

      // 消息相关
      'sendMessage': _jsSendMessage,
      'getMessages': _jsGetMessages,
      'deleteMessage': _jsDeleteMessage,

      // 用户相关
      'getCurrentUser': _jsGetCurrentUser,
      'getAIUser': _jsGetAIUser,
    };
  }

  // ==================== JS API 实现 ====================

  /// 同步测试 API
  String _jsTestSync() {
    return jsonEncode({
      'status': 'ok',
      'message': '同步测试成功！',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 获取所有频道
  Future<String> _jsGetChannels() async {
    final channels = channelService.channels;
    return jsonEncode(channels.map((c) => c.toJson()).toList());
  }

  /// 创建频道
  Future<String> _jsCreateChannel(String name, [String? avatar]) async {
    final channel = Channel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: name,
      icon: Icons.chat, // 默认图标
      messages: [], // 空消息列表
      backgroundColor: color, // 使用插件主题色
    );
    await channelService.createChannel(channel);
    return jsonEncode(channel.toJson());
  }

  /// 删除频道
  Future<bool> _jsDeleteChannel(String channelId) async {
    await channelService.deleteChannel(channelId);
    return true;
  }

  /// 发送消息
  Future<String> _jsSendMessage(
      String channelId, String content, String type) async {
    // 解析消息类型
    MessageType messageType;
    try {
      messageType = MessageType.values.firstWhere(
        (t) => t.name == type.toLowerCase(),
        orElse: () => MessageType.sent,
      );
    } catch (e) {
      messageType = MessageType.sent;
    }

    // 创建消息
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      user: userService.currentUser, // 使用 User 对象
      type: messageType,
      date: DateTime.now(), // 使用 date 而不是 timestamp
    );

    // 保存消息
    await channelService.addMessage(channelId, message);

    // 序列化消息（toJson 返回 Future）
    final messageJson = await message.toJson();
    return jsonEncode(messageJson);
  }

  /// 获取频道消息
  Future<String> _jsGetMessages(String channelId, [int? limit]) async {
    final messages = await channelService.getChannelMessages(channelId);
    if (messages == null) {
      return jsonEncode([]);
    }

    // 如果指定了 limit，只返回最新的 N 条消息
    final List<Message> resultMessages = limit != null && limit < messages.length
        ? messages.sublist(messages.length - limit)
        : messages;

    // 序列化所有消息（toJson 返回 Future）
    final messagesJsonList = await Future.wait(
      resultMessages.map((m) => m.toJson()),
    );
    return jsonEncode(messagesJsonList);
  }

  /// 删除消息
  Future<bool> _jsDeleteMessage(String channelId, String messageId) async {
    final messages = await channelService.getChannelMessages(channelId);
    if (messages == null) return false;

    messages.removeWhere((m) => m.id == messageId);
    await channelService.saveMessages(channelId, messages);
    return true;
  }

  /// 获取当前用户
  Future<String> _jsGetCurrentUser() async {
    final user = userService.currentUser;
    return jsonEncode(user.toJson());
  }

  /// 获取所有用户
  Future<String> _jsGetAIUser() async {
    // UserService 没有 getAIUser 方法，返回所有用户列表
    // 调用者可以根据用户名筛选 AI 用户
    final users = userService.getAllUsers();
    return jsonEncode(users.map((u) => u.toJson()).toList());
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }
}
