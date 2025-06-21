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

class ChatPlugin extends BasePlugin with ChangeNotifier {
  static ChatPlugin? _instance;
  static ChatPlugin get instance {
    _instance ??= ChatPlugin();
    return _instance!;
  }

  // Services
  late final ChannelService channelService;
  late final MessageService messageService;
  late final SettingsService settingsService;
  late final UIService uiService;
  late final UserService userService;

  // 检查插件是否已完全初始化
  bool get isInitialized {
    try {
      storage;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Plugin metadata
  late String _name = 'Chat';
  late String _description = 'A plugin for chatting with other users';

  @override
  String get id => 'chat';

  @override
  String get name => _name;

  @override
  String get description => _description;

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

  // 更新本地化文本
  void updateLocalizedStrings(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
    if (l10n != null) {
      _name = l10n.chatPluginName;
      _description = l10n.chatPluginDescription;
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    // 返回聊天插件的主视图
    return uiService.buildMainView(context);
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
