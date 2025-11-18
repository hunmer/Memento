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

  /// 手动触发刷新（用于外部事件变化时通知监听者）
  void refresh() {
    notifyListeners();
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

  /// 获取所有频道
  Future<String> _jsGetChannels(Map<String, dynamic> params) async {
    final channels = channelService.channels;
    return jsonEncode(channels.map((c) => c.toJson()).toList());
  }

  /// 创建频道
  Future<String> _jsCreateChannel(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    try {
      // 可选参数

      final channel = Channel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        icon: Icons.chat, // 默认图标
        messages: [], // 空消息列表
        backgroundColor: color, // 使用插件主题色
      );
      await channelService.createChannel(channel);
      return jsonEncode(channel.toJson());
    } catch (e) {
      return jsonEncode({'error': '创建频道失败: ${e.toString()}'});
    }
  }

  /// 删除频道
  Future<String> _jsDeleteChannel(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? channelId = params['channelId'];
    if (channelId == null || channelId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: channelId'});
    }

    try {
      await channelService.deleteChannel(channelId);
      return jsonEncode({'success': true});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 发送消息
  Future<String> _jsSendMessage(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? channelId = params['channelId'];
    final String? content = params['content'];

    if (channelId == null || channelId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: channelId'});
    }
    if (content == null || content.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    try {
      // 可选参数
      final String? type = params['type'];

      // 解析消息类型
      MessageType messageType;
      try {
        messageType = MessageType.values.firstWhere(
          (t) => t.name == (type ?? 'sent').toLowerCase(),
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
    } catch (e) {
      return jsonEncode({'error': '发送消息失败: ${e.toString()}'});
    }
  }

  /// 获取频道消息
  Future<String> _jsGetMessages(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? channelId = params['channelId'];
    if (channelId == null || channelId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: channelId'});
    }

    // 可选参数
    final int? limit = params['limit'];

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
  Future<String> _jsDeleteMessage(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? channelId = params['channelId'];
    final String? messageId = params['messageId'];

    if (channelId == null || channelId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: channelId'});
    }
    if (messageId == null || messageId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: messageId'});
    }

    try {
      final messages = await channelService.getChannelMessages(channelId);
      if (messages == null) {
        return jsonEncode({'success': false, 'error': '频道不存在'});
      }

      messages.removeWhere((m) => m.id == messageId);
      await channelService.saveMessages(channelId, messages);
      return jsonEncode({'success': true});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 获取当前用户
  Future<String> _jsGetCurrentUser(Map<String, dynamic> params) async {
    final user = userService.currentUser;
    return jsonEncode(user.toJson());
  }

  /// 获取所有用户
  Future<String> _jsGetAIUser(Map<String, dynamic> params) async {
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
