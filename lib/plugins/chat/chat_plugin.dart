import 'dart:convert';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/chat/widgets/chat_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'services/channel_service.dart';
import 'services/message_service.dart';
import 'services/settings_service.dart';
import 'services/ui_service.dart';
import 'services/user_service.dart';
import 'services/widget_service.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(channel: channel),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开频道失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有频道
  /// 支持分页参数: offset, count
  Future<String> _jsGetChannels(Map<String, dynamic> params) async {
    final channels = channelService.channels;
    final channelJsonList = channels.map((c) => c.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        channelJsonList,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(channelJsonList);
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
      final String? channelId = params['channelId'];

      final channel = Channel(
        id: channelId ?? const Uuid().v4(), // 支持自定义频道ID，默认使用UUID
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
        id: const Uuid().v4(),
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
  /// 支持分页参数: offset, count (或旧版 limit)
  Future<String> _jsGetMessages(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? channelId = params['channelId'];
    if (channelId == null || channelId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: channelId'});
    }

    // 分页参数
    final int? offset = params['offset'];
    final int? count = params['count'];
    final int? limit = params['limit']; // 兼容旧版

    final messages = await channelService.getChannelMessages(channelId);
    if (messages == null) {
      return jsonEncode(offset != null || count != null
        ? {'data': [], 'total': 0, 'offset': 0, 'count': 0, 'hasMore': false}
        : []);
    }

    // 序列化所有消息（toJson 返回 Future）
    final messagesJsonList = await Future.wait(
      messages.map((m) => m.toJson()),
    );

    // 新版分页逻辑
    if (offset != null || count != null) {
      final paginated = _paginate(
        messagesJsonList,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版 limit 参数：只返回最新的 N 条消息
    if (limit != null && limit < messagesJsonList.length) {
      final limitedMessages = messagesJsonList.sublist(messagesJsonList.length - limit);
      return jsonEncode(limitedMessages);
    }

    // 无分页参数时返回全部数据
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
      // 获取要删除的消息
      final message = channelService.getMessageById(messageId);
      if (message == null) {
        return jsonEncode({'success': false, 'error': '消息不存在'});
      }

      // 使用 ChannelService 的 deleteMessage 方法正确删除消息
      final success = await channelService.deleteMessage(message);
      return jsonEncode({'success': success});
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

  // ==================== 频道查找方法 ====================

  /// 通用频道查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindChannelBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final channels = channelService.channels;
    final List<Channel> matchedChannels = [];

    for (final channel in channels) {
      final channelJson = channel.toJson();

      // 检查字段是否匹配
      if (channelJson.containsKey(field) && channelJson[field] == value) {
        matchedChannels.add(channel);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      final channelJsonList = matchedChannels.map((c) => c.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          channelJsonList,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(channelJsonList);
    } else {
      if (matchedChannels.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedChannels.first.toJson());
    }
  }

  /// 根据ID查找频道
  /// @param params.id 频道ID (必需)
  Future<String> _jsFindChannelById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final channels = channelService.channels;
    final channel = channels.firstWhere(
      (c) => c.id == id,
      orElse:
          () => Channel(
            id: '',
            title: '',
            icon: Icons.error,
            messages: [],
            backgroundColor: Colors.transparent,
          ),
    );

    if (channel.id.isEmpty) {
      return jsonEncode(null);
    }

    return jsonEncode(channel.toJson());
  }

  /// 根据标题查找频道
  /// @param params.title 频道标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindChannelByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final channels = channelService.channels;
    final List<Channel> matchedChannels = [];

    for (final channel in channels) {
      bool matches = false;
      if (fuzzy) {
        matches = channel.title.contains(title);
      } else {
        matches = channel.title == title;
      }

      if (matches) {
        matchedChannels.add(channel);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final channelJsonList = matchedChannels.map((c) => c.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          channelJsonList,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(channelJsonList);
    } else {
      if (matchedChannels.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedChannels.first.toJson());
    }
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
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final String? channelId = params['channelId'];
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final List<Message> matchedMessages = [];

    // 如果指定了 channelId，只在该频道中查找
    if (channelId != null && channelId.isNotEmpty) {
      final messages = await channelService.getChannelMessages(channelId);
      if (messages != null) {
        for (final message in messages) {
          final messageJson = await message.toJson();
          if (messageJson.containsKey(field) && messageJson[field] == value) {
            matchedMessages.add(message);
            if (!findAll) break;
          }
        }
      }
    } else {
      // 在所有频道中查找
      for (final channel in channelService.channels) {
        final messages = await channelService.getChannelMessages(channel.id);
        if (messages != null) {
          for (final message in messages) {
            final messageJson = await message.toJson();
            if (messageJson.containsKey(field) && messageJson[field] == value) {
              matchedMessages.add(message);
              if (!findAll) break;
            }
          }
        }
        if (!findAll && matchedMessages.isNotEmpty) break;
      }
    }

    if (findAll) {
      final messagesJsonList = await Future.wait(
        matchedMessages.map((m) => m.toJson()),
      );

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          messagesJsonList,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(messagesJsonList);
    } else {
      if (matchedMessages.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(await matchedMessages.first.toJson());
    }
  }

  /// 根据ID查找消息
  /// @param params.id 消息ID (必需)
  /// @param params.channelId 限定在特定频道内查找 (可选)
  Future<String> _jsFindMessageById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final String? channelId = params['channelId'];

    Message? foundMessage;

    if (channelId != null && channelId.isNotEmpty) {
      final messages = await channelService.getChannelMessages(channelId);
      if (messages != null) {
        foundMessage = messages.firstWhere(
          (m) => m.id == id,
          orElse:
              () => Message(
                id: '',
                content: '',
                user: userService.currentUser,
                type: MessageType.sent,
                date: DateTime.now(),
              ),
        );
      }
    } else {
      // 在所有频道中查找
      for (final channel in channelService.channels) {
        final messages = await channelService.getChannelMessages(channel.id);
        if (messages != null) {
          foundMessage = messages.firstWhere(
            (m) => m.id == id,
            orElse:
                () => Message(
                  id: '',
                  content: '',
                  user: userService.currentUser,
                  type: MessageType.sent,
                  date: DateTime.now(),
                ),
          );
          if (foundMessage.id.isNotEmpty) break;
        }
      }
    }

    if (foundMessage == null || foundMessage.id.isEmpty) {
      return jsonEncode(null);
    }

    return jsonEncode(await foundMessage.toJson());
  }

  /// 根据内容查找消息
  /// @param params.content 消息内容 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.channelId 限定在特定频道内查找 (可选)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindMessageByContent(Map<String, dynamic> params) async {
    final String? content = params['content'];
    if (content == null || content.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final String? channelId = params['channelId'];
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final List<Message> matchedMessages = [];

    // 如果指定了 channelId，只在该频道中查找
    if (channelId != null && channelId.isNotEmpty) {
      final messages = await channelService.getChannelMessages(channelId);
      if (messages != null) {
        for (final message in messages) {
          bool matches = false;
          if (fuzzy) {
            matches = message.content.contains(content);
          } else {
            matches = message.content == content;
          }

          if (matches) {
            matchedMessages.add(message);
            if (!findAll) break;
          }
        }
      }
    } else {
      // 在所有频道中查找
      for (final channel in channelService.channels) {
        final messages = await channelService.getChannelMessages(channel.id);
        if (messages != null) {
          for (final message in messages) {
            bool matches = false;
            if (fuzzy) {
              matches = message.content.contains(content);
            } else {
              matches = message.content == content;
            }

            if (matches) {
              matchedMessages.add(message);
              if (!findAll) break;
            }
          }
        }
        if (!findAll && matchedMessages.isNotEmpty) break;
      }
    }

    if (findAll) {
      final messagesJsonList = await Future.wait(
        matchedMessages.map((m) => m.toJson()),
      );

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          messagesJsonList,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(messagesJsonList);
    } else {
      if (matchedMessages.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(await matchedMessages.first.toJson());
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }
}
