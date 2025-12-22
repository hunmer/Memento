import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import '../models/route_context.dart';

/// 上下文查询抽屉
///
/// 通过创建临时频道，使用 agent_chat 插件进行上下文查询
class ContextQueryDrawer extends StatefulWidget {
  /// 路由上下文信息
  final RouteContext routeContext;

  const ContextQueryDrawer({
    super.key,
    required this.routeContext,
  });

  @override
  State<ContextQueryDrawer> createState() => _ContextQueryDrawerState();
}

class _ContextQueryDrawerState extends State<ContextQueryDrawer> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 延迟打开聊天界面，避免在 build 过程中调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openChatInterface();
    });
  }

  /// 打开聊天界面
  Future<void> _openChatInterface() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取 agent_chat 插件
      final plugin =
          PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;

      if (plugin == null) {
        Toast.error('Agent Chat 插件未加载');
        if (mounted) Navigator.pop(context);
        return;
      }

      // 等待插件初始化
      if (!plugin.isInitialized) {
        debugPrint('等待 Agent Chat 插件初始化...');
        await Future.delayed(const Duration(milliseconds: 100));
        if (!plugin.isInitialized) {
          Toast.error('Agent Chat 插件初始化超时');
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // 尝试从路由配置中读取上次使用的 Agent 配置
      final routeConfig = plugin.getRouteAgentConfig(widget.routeContext.routeName);
      final agentId = routeConfig?.agentId;
      final agentChain = routeConfig?.agentChain;

      // 创建或获取临时会话
      final conversation = await plugin.getOrCreateTemporaryConversation(
        routeName: widget.routeContext.routeName,
        title: '询问: ${widget.routeContext.description}',
        agentId: agentId,
        agentChain: agentChain,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 关闭当前抽屉
      Navigator.pop(context);

      // 使用 SmoothBottomSheet 展示 ChatScreen
      await _showChatScreen(plugin, conversation);
    } catch (e) {
      debugPrint('打开聊天界面失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Toast.error('打开聊天界面失败: $e');
        Navigator.pop(context);
      }
    }
  }

  /// 展示聊天界面
  Future<void> _showChatScreen(
    AgentChatPlugin plugin,
    Conversation conversation,
  ) async {
    if (!mounted) return;

    final controller = plugin.conversationController;
    if (controller == null) return;

    // 记录对话打开前的配置
    final initialAgentId = conversation.agentId;
    final initialAgentChain = conversation.agentChain;

    // 展示聊天界面
    await SmoothBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ChatScreen(
          conversation: conversation,
          storage: controller.storage,
          conversationService: controller.conversationService,
          getSettings: () => plugin.settings,
          initialMessage: widget.routeContext.description, // 将上下文描述设为初始消息
        ),
      ),
    );

    // 聊天界面关闭后，检查 Agent 配置是否发生变化
    if (!mounted) return;

    try {
      // 重新获取会话以获取最新配置
      final updatedConversation =
          controller.conversationService.getConversation(conversation.id);

      if (updatedConversation != null) {
        final hasAgentIdChanged =
            updatedConversation.agentId != initialAgentId;
        final hasAgentChainChanged =
            updatedConversation.agentChain != initialAgentChain;

        // 如果配置发生变化，保存到路由配置
        if (hasAgentIdChanged || hasAgentChainChanged) {
          await plugin.saveRouteAgentConfig(
            widget.routeContext.routeName,
            updatedConversation.agentId,
            updatedConversation.agentChain,
          );
          debugPrint('已保存路由 ${widget.routeContext.routeName} 的 Agent 配置');
        }
      }
    } catch (e) {
      debugPrint('保存路由 Agent 配置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.assistant, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '询问当前上下文',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const Divider(height: 24),

          // 路由信息展示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 20, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.routeContext.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 加载指示器
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在打开聊天界面...'),
                  ],
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('初始化中...'),
              ),
            ),

          const SizedBox(height: 24),

          // 取消按钮
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('app_cancel'.tr),
          ),
        ],
      ),
    );
  }
}
