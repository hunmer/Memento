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
import 'services/channel_service.dart';
import 'services/message_service.dart';
import 'services/settings_service.dart';
import 'services/ui_service.dart';
import 'services/user_service.dart';
import 'services/widget_service.dart';
import 'package:shared_models/usecases/chat/chat_usecase.dart';

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
  late final ChannelService channelService;
  late final MessageService messageService;
  late final SettingsService settingsService;
  late final UIService uiService;
  late final UserService userService;

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

    // 初始化小组件服务
    await ChatWidgetService.initialize();

    // 创建 UseCase 实例
    chatUseCase = ChatUseCase(
      ClientChatRepository(
        channelService: channelService,
        userService: userService,
        pluginColor: color,
      ),
    );

    // 注册数据选择器
    _registerDataSelectors();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    // 1. 频道选择器（单级）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'chat.channel',
      pluginId: id,
      name: '选择频道',
      description: '选择一个聊天频道',
      icon: Icons.chat_bubble_outline,
      color: color,
      steps: [
        SelectorStep(
          id: 'channel',
          title: '频道列表',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          emptyText: '暂无频道，请先创建',
          dataLoader: (_) async {
            return channelService.channels.map((channel) => SelectableItem(
              id: channel.id,
              title: channel.title,
              icon: channel.icon,
              color: channel.backgroundColor,
              subtitle: channel.messages.isNotEmpty
                  ? channel.messages.last.content
                  : null,
              rawData: channel,
            )).toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
      ],
    ));

    // 2. 消息选择器（两级：频道 -> 消息）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'chat.message',
      pluginId: id,
      name: '选择消息',
      description: '选择一条聊天消息',
      icon: Icons.message,
      color: color,
      steps: [
        // 第一级：选择频道
        SelectorStep(
          id: 'channel',
          title: '选择频道',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          emptyText: '暂无频道',
          dataLoader: (_) async {
            return channelService.channels.map((channel) => SelectableItem(
              id: channel.id,
              title: channel.title,
              icon: channel.icon,
              color: channel.backgroundColor,
              subtitle: '${channel.messages.length} 条消息',
              rawData: channel,
            )).toList();
          },
        ),
        // 第二级：选择消息
        SelectorStep(
          id: 'message',
          title: '选择消息',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          emptyText: '该频道暂无消息',
          dataLoader: (previousSelections) async {
            final channel = previousSelections['channel'] as Channel;
            // 加载频道消息
            final messages = await channelService.getChannelMessages(channel.id);
            if (messages == null) return [];

            return messages.map((message) => SelectableItem(
              id: message.id,
              title: message.content.length > 50
                  ? '${message.content.substring(0, 50)}...'
                  : message.content,
              subtitle: _formatMessageDate(message.date),
              icon: _getMessageIcon(message.type),
              rawData: message,
              metadata: {'channelId': channel.id},
            )).toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
      ],
    ));
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.audio:
        return Icons.audiotrack;
      case MessageType.file:
        return Icons.attach_file;
      default:
        return Icons.text_fields;
    }
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  String? getPluginName(context) {
    return 'chat_name'.tr;
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
    return ChatBottomBar(plugin: this);
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

      // 频道查找方法
      'findChannelBy': _jsFindChannelBy,
      'findChannelById': _jsFindChannelById,
      'findChannelByTitle': _jsFindChannelByTitle,

      // 消息查找方法
      'findMessageBy': _jsFindMessageBy,
      'findMessageById': _jsFindMessageById,
      'findMessageByContent': _jsFindMessageByContent,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有频道
  /// 支持分页参数: offset, count
  Future<String> _jsGetChannels(Map<String, dynamic> params) async {
    final result = await chatUseCase.getChannels(params);
    return result.toJsonString();
  }

  /// 创建频道
  Future<String> _jsCreateChannel(Map<String, dynamic> params) async {
    final result = await chatUseCase.createChannel(params);
    return result.toJsonString();
  }

  /// 删除频道
  Future<String> _jsDeleteChannel(Map<String, dynamic> params) async {
    final result = await chatUseCase.deleteChannel(params);
    return result.toJsonString();
  }

  /// 发送消息
  Future<String> _jsSendMessage(Map<String, dynamic> params) async {
    final result = await chatUseCase.sendMessage(params);
    return result.toJsonString();
  }

  /// 获取频道消息
  /// 支持分页参数: offset, count (或旧版 limit)
  Future<String> _jsGetMessages(Map<String, dynamic> params) async {
    final result = await chatUseCase.getMessages(params);
    return result.toJsonString();
  }

  /// 删除消息
  Future<String> _jsDeleteMessage(Map<String, dynamic> params) async {
    final result = await chatUseCase.deleteMessage(params);
    return result.toJsonString();
  }

  /// 获取当前用户
  Future<String> _jsGetCurrentUser(Map<String, dynamic> params) async {
    final result = await chatUseCase.getCurrentUser(params);
    return result.toJsonString();
  }

  /// 获取 AI 用户
  Future<String> _jsGetAIUser(Map<String, dynamic> params) async {
    final result = await chatUseCase.getAIUser();
    return result.toJsonString();
  }

  // ==================== 频道查找方法 ====================

  /// 通用频道查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindChannelBy(Map<String, dynamic> params) async {
    final result = await chatUseCase.findChannelBy(params);
    return result.toJsonString();
  }

  /// 根据ID查找频道
  /// @param params.id 频道ID (必需)
  Future<String> _jsFindChannelById(Map<String, dynamic> params) async {
    final result = await chatUseCase.findChannelById(params);
    return result.toJsonString();
  }

  /// 根据标题查找频道
  /// @param params.title 频道标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindChannelByTitle(Map<String, dynamic> params) async {
    final result = await chatUseCase.findChannelByTitle(params);
    return result.toJsonString();
  }

  // ==================== 消息查找方法 ====================

  /// 通用消息查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.channelId 限定在特定频道内查找 (可选)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindMessageBy(Map<String, dynamic> params) async {
    final result = await chatUseCase.findMessageBy(params);
    return result.toJsonString();
  }

  /// 根据ID查找消息
  /// @param params.id 消息ID (必需)
  /// @param params.channelId 限定在特定频道内查找 (可选)
  Future<String> _jsFindMessageById(Map<String, dynamic> params) async {
    final result = await chatUseCase.findMessageById(params);
    return result.toJsonString();
  }

  /// 根据内容查找消息
  /// @param params.content 消息内容 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.channelId 限定在特定频道内查找 (可选)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindMessageByContent(Map<String, dynamic> params) async {
    final result = await chatUseCase.findMessageByContent(params);
    return result.toJsonString();
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
