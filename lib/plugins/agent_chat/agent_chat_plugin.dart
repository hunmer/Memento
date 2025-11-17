import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_manager.dart';
import 'controllers/conversation_controller.dart';
import 'screens/conversation_list_screen/conversation_list_screen.dart';
import 'screens/agent_chat_settings_screen.dart';
import 'services/tool_service.dart';
import '../openai/openai_plugin.dart';
// import 'l10n/agent_chat_localizations.dart';

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
  ConversationController get conversationController => _conversationController!;

  /// 检查是否已初始化
  bool get isInitialized => _conversationController != null &&
      _conversationController!.isInitialized;

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
    // 初始化控制器
    _conversationController = ConversationController(storage: storage);
    await _conversationController!.initialize();

    // 初始化工具服务
    await ToolService.initialize();

    // 注册插件分析处理器（如果 OpenAI 插件可用）
    final openaiPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
    if (openaiPlugin != null) {
      JSBridgeManager.instance.registerPluginAnalysisHandler(
        (methodName, params) async {
          // 调用 OpenAI 插件的 Prompt 替换控制器
          return await openaiPlugin.getPromptReplacementController().executeMethod(
            methodName,
            params,
          );
        },
      );
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 调用初始化方法
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ConversationListScreen();
  }

  @override
  String? getPluginName(context) {
    // TODO: 集成国际化后返回翻译后的名称
    return 'Agent Chat';
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return AgentChatSettingsScreen(plugin: this);
  }
}

/// Agent Chat 主视图（路由入口）
class AgentChatMainView extends StatefulWidget {
  const AgentChatMainView({super.key});

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
    _initializeFuture = plugin.isInitialized
        ? Future.value()
        : _waitForInitialization();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
                  Text('初始化失败: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
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
