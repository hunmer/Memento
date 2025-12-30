import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/widgets/adaptive_image.dart';

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
    return Material(
      key: _cardKey,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _editAgent(),
        onLongPress: () => _showActionMenu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Icon
            Expanded(child: Center(child: _buildAgentIcon())),

            // Agent Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '服务商: ${agent.serviceProviderId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildTags(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentIcon() {
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getColorForServiceProvider(
                agent.serviceProviderId,
              ).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: AdaptiveImage(
              imagePath: agent.avatarUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    
    // 如果有自定义图标，使用自定义图标
    if (agent.icon != null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: agent.iconColor ?? _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(
          agent.icon,
          size: 40,
          color: Colors.white,
        ),
      );
    }
    
    // 默认图标
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Color _getColorForServiceProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return Colors.green;
      case 'azure':
        return Colors.blue;
      case 'ollama':
        return Colors.orange;
      case 'deepseek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTags() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          agent.tags.take(2).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            );
          }).toList(),
    );
  }
}
