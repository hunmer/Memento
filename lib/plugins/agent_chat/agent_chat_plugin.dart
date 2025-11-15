import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import 'controllers/conversation_controller.dart';
import 'screens/conversation_list_screen/conversation_list_screen.dart';
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

  late final ConversationController conversationController;

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
    conversationController = ConversationController(storage: storage);
    await conversationController.initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ConversationListScreen(controller: conversationController);
  }

  @override
  String? getPluginName(context) {
    // TODO: 集成国际化后返回翻译后的名称
    return 'Agent Chat';
  }
}
