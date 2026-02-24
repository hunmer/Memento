import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/widgets/common/agent_card.dart';

/// Agent 卡片组件
///
/// 使用声明式构建，通过 AgentCardWidget 渲染 UI
class AgentCard extends StatefulWidget {
  final AIAgent agent;

  const AgentCard({super.key, required this.agent});

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> {
  final GlobalKey _cardKey = GlobalKey();

  AIAgent get agent => widget.agent;

  /// 显示操作菜单
  void _showActionMenu(BuildContext context) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              _editAgent();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteAgent();
            },
          ),
        ],
      ),
    );
  }

  /// 编辑 Agent
  void _editAgent() {
    NavigationHelper.openContainerWithHero(
      context,
      (context) => AgentEditScreen(agent: agent),
      sourceKey: _cardKey,
      heroTag: 'agent_card_${agent.id}',
    );
  }

  /// 删除 Agent
  Future<void> _deleteAgent() async {
    final controller = OpenAIPlugin.instance.controller;
    await controller.deleteAgent(agent.id);
    Get.snackbar(
      'openai_agentDeleted'.tr,
      '${agent.name} 已被删除',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用声明式构建，通过 AgentCardWidget 渲染 UI
    return AgentCardWidget(
      key: _cardKey,
      name: agent.name,
      description: agent.description,
      serviceProviderId: agent.serviceProviderId,
      tags: agent.tags,
      avatarUrl: agent.avatarUrl,
      iconCodePoint: agent.icon?.codePoint,
      iconColorValue: agent.iconColor?.value,
      onTap: () => _editAgent(),
      onLongPress: () => _showActionMenu(context),
    );
  }
}
