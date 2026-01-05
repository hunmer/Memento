import 'dart:convert';

import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/chat/widgets/chat_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:shared_models/shared_models.dart';
import 'repositories/client_chat_repository.dart';
import 'services/chat_data_service.dart';
import 'services/chat_config_service.dart';
import 'services/ui_service.dart';
import 'services/widget_service.dart';
import 'services/tag_service.dart';
import 'package:shared_models/usecases/chat/chat_usecase.dart';

part 'chat_js_api.dart';
part 'chat_data_selectors.dart';

class ChatMainView extends StatefulWidget {
  final String? channelId;
  const ChatMainView({super.key, this.channelId});
  @override
  State<ChatMainView> createState() => _ChatMainViewState();
}

class _ChatMainViewState extends State<ChatMainView> {
  late ChatPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin;

    // 如果有 channelId，在初始化完成后自动打开该频道
    if (widget.channelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openChannel();
      });
    }
  }

  Future<void> _openChannel() async {
    if (!mounted || widget.channelId == null) return;

    try {
      // 从频道列表中查找指定频道
      final channel = _plugin.channelService.channels.firstWhere(
        (c) => c.id == widget.channelId,
        orElse: () => throw Exception('频道不存在'),
      );

      // 设置当前频道
      _plugin.channelService.setCurrentChannel(channel);

      // 导航到聊天界面
      NavigationHelper.push(context, ChatScreen(channel: channel),
      );
    } catch (e) {
      if (mounted) {
        Toast.error('打开频道失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBottomBar(plugin: _plugin);
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
  late final ChatDataService dataService;
  late final ChatConfigService configService;
  late final UIService uiService;
  late final TagService tagService;

  // 向后兼容的 getters (逐步迁移)
  ChatDataService get channelService => dataService;
  ChatDataService get messageService => dataService;
  ChatConfigService get settingsService => configService;
  ChatConfigService get userService => configService;

  // UseCase
  late final ChatUseCase chatUseCase;

  // Prompt controller
  @override
  String get id => 'chat';

  @override
  Color get color => Colors.indigoAccent;

  @override
  IconData get icon => Icons.chat_bubble;

  @override
  Future<void> initialize() async {
    // Initialize services
    dataService = ChatDataService(this);
    configService = ChatConfigService(this);
    tagService = TagService(messageService: dataService);
    uiService = UIService(configService, configService, this);

    // Initialize all services
    await configService.initialize();
    await dataService.initialize();
    await uiService.initialize();

    // Initialize prompt controller

    // 初始化小组件服务
    await ChatWidgetService.initialize();

    // 创建 UseCase 实例
    chatUseCase = ChatUseCase(
      ClientChatRepository(
        dataService: dataService,
        configService: configService,
        pluginColor: color,
      ),
    );

    // 注册数据选择器
    _registerDataSelectors();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }


  @override
  String? getPluginName(context) {
    return 'chat_name'.tr;
  }

  /// 根据消息ID获取消息
  /// 代理到 dataService.getMessageById
  Future<Message?> getMessage(String messageId) async {
    return dataService.getMessageById(messageId);
  }

  /// 手动触发刷新（用于外部事件变化时通知监听者）
  void refresh() {
    notifyListeners();
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chat_name'.tr),
      ),
      body: StatefulBuilder(
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
      ),
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ChatBottomBar(plugin: this);
  }

  @override
  Widget? buildCardView(BuildContext context) {
    return uiService.buildCardView(context);
  }


  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }
}
