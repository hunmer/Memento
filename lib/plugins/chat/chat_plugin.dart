import 'package:Memento/plugins/chat/models/message.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'services/channel_service.dart';
import 'services/message_service.dart';
import 'services/settings_service.dart';
import 'services/ui_service.dart';
import 'services/user_service.dart';
import 'l10n/chat_localizations.dart';

class ChatMainView extends StatefulWidget {
  const ChatMainView();
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

class ChatPlugin extends BasePlugin with ChangeNotifier {
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
  @override
  String get id => 'chat';

  @override
  String get name => 'Chat';

  @override
  String get description => 'A plugin for chatting with other users';

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
            // User profile card managed by UIService
            uiService.buildUserProfileCard(context, setState),
            const SizedBox(height: 16),
            // Chat settings card managed by UIService
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
    // 返回聊天插件的卡片视图
    return uiService.buildCardView(context);
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 在这里注册插件到应用
    // 例如：注册路由、初始化必要的配置等
    await initialize();
  }
}
