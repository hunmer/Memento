import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'controllers/conversation_controller.dart';
import 'screens/conversation_list_screen/conversation_list_screen.dart';
import 'screens/chat_screen/chat_screen.dart';
import 'screens/agent_chat_settings_screen.dart';
import 'services/tool_service.dart';
import 'services/tool_template_service.dart';
import 'services/widget_service.dart';
import 'models/chat_message.dart';
import 'l10n/agent_chat_localizations.dart';

/// Agent Chat 插件
///
/// 专注于一对一AI对话的极简聊天插件
///
/// 主要功能：
/// - 多会话管理（分组、搜索、筛选）
/// - Agent绑定（每个会话一个Agent）
/// - 文件上传（图片+文档，多文件）
/// - 上下文管理（全局+会话级设置）
/// - Token统计（全局+每条消息）
/// - 流式响应（打字机效果）
/// - 消息编辑/删除/重新生成
/// - Markdown渲染
class AgentChatPlugin extends PluginBase with ChangeNotifier {
  static AgentChatPlugin? _instance;
  static AgentChatPlugin get instance => _instance!;

  ConversationController? _conversationController;
  ConversationController? get conversationController => _conversationController;

  ToolTemplateService? _templateService;
  ToolTemplateService? get templateService => _templateService;

  /// 检查是否已初始化
  bool get isInitialized =>
      _conversationController != null && _conversationController!.isInitialized;

  AgentChatPlugin() {
    _instance = this;
  }

  @override
  String get id => 'agent_chat';

  @override
  IconData? get icon => Icons.chat_bubble_outline;

  @override
  Color? get color => const Color(0xFF2196F3);

  @override
  Future<void> initialize() async {
    // 加载插件配置（包括语音识别配置等）
    await loadSettings({});

    // 初始化控制器
    _conversationController = ConversationController(storage: storage);
    await _conversationController!.initialize();

    // 初始化工具模板服务
    _templateService = ToolTemplateService(storage);
    await _templateService!.ensureInitialized();

    // 初始化工具服务
    await ToolService.initialize();

    // 初始化小组件服务
    await AgentChatWidgetService.initialize();
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 调用初始化方法
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const AgentChatMainView();
  }

  @override
  String? getPluginName(context) {
    // TODO: 集成国际化后返回翻译后的名称
    return 'AI 对话';
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return AgentChatSettingsScreen(plugin: this);
  }

  // ==================== 小组件统计方法 ====================

  /// 获取总对话数
  int getTotalConversationsCount() {
    try {
      return conversationController?.conversations.length ?? 0;
    } catch (e) {
      debugPrint('获取总对话数失败: $e');
      return 0;
    }
  }

  /// 获取今日消息数
  /// 统计所有会话中今天发送的消息总数
  Future<int> getTodayMessagesCount() async {
    try {
      final controller = conversationController;
      if (controller == null) {
        debugPrint('conversationController 未初始化');
        return 0;
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      int count = 0;

      // 遍历所有会话
      for (final conversation in controller.conversations) {
        try {
          // 加载该会话的消息
          final data = await storage.read('agent_chat/messages/${conversation.id}');
          if (data is List) {
            final messages = data
                .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
                .toList();

            // 统计今日消息
            count += messages.where((msg) {
              return msg.timestamp.isAfter(todayStart) &&
                  msg.timestamp.isBefore(todayEnd);
            }).length;
          }
        } catch (e) {
          debugPrint('加载会话 ${conversation.id} 的消息失败: $e');
          continue;
        }
      }

      return count;
    } catch (e) {
      debugPrint('获取今日消息数失败: $e');
      return 0;
    }
  }

  /// 获取活跃会话数
  /// 定义: 最近7天内有消息的会话
  Future<int> getActiveConversationsCount() async {
    try {
      final controller = conversationController;
      if (controller == null) {
        debugPrint('conversationController 未初始化');
        return 0;
      }

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      int count = 0;

      for (final conversation in controller.conversations) {
        // 检查lastMessageAt是否在7天内
        if (conversation.lastMessageAt != null &&
            conversation.lastMessageAt.isAfter(sevenDaysAgo)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      debugPrint('获取活跃会话数失败: $e');
      return 0;
    }
  }
}

/// Agent Chat 主视图（路由入口）
class AgentChatMainView extends StatefulWidget {
  /// 可选的对话ID - 如果提供，将直接打开该对话的聊天界面
  final String? conversationId;

  const AgentChatMainView({super.key, this.conversationId});

  @override
  State<AgentChatMainView> createState() => _AgentChatMainViewState();
}

class _AgentChatMainViewState extends State<AgentChatMainView> {
  late Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    final plugin = AgentChatPlugin.instance;

    // 如果已初始化，直接完成；否则等待初始化
    _initializeFuture =
        plugin.isInitialized ? Future.value() : _waitForInitialization();

    // 如果传入了conversationId，在初始化完成后直接打开对话
    if (widget.conversationId != null) {
      _initializeFuture.then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openConversation();
        });
      });
    }
  }

  Future<void> _waitForInitialization() async {
    final plugin = AgentChatPlugin.instance;

    // 等待插件初始化（最多等待5秒）
    int attempts = 0;
    while (!plugin.isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!plugin.isInitialized) {
      throw Exception('插件初始化超时');
    }
  }

  /// 打开指定的对话
  Future<void> _openConversation() async {
    if (!mounted || widget.conversationId == null) return;

    try {
      final plugin = AgentChatPlugin.instance;
      final controller = plugin.conversationController;

      if (controller == null) {
        debugPrint('conversationController 未初始化');
        return;
      }

      // 查找指定的对话
      final conversation = controller.conversations.firstWhere(
        (c) => c.id == widget.conversationId,
        orElse: () => throw Exception('对话不存在'),
      );

      // 导航到聊天界面
      await NavigationHelper.push(context, ChatScreen(
            conversation: conversation,
            storage: controller.storage,
            conversationService: controller.conversationService,
            getSettings: () => plugin.settings,),
      );
    } catch (e) {
      if (mounted) {
        toastService.showToast('打开对话失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(AgentChatLocalizations.of(context).initializationFailed('${snapshot.error}')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AgentChatLocalizations.of(context).goBack),
                  ),
                ],
              ),
            ),
          );
        }

        return const ConversationListScreen();
      },
    );
  }
}
