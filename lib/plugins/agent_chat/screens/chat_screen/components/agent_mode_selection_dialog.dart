import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../../models/agent_chain_node.dart';

/// Agent 模式选择对话框
///
/// 提供单 Agent 模式和 Agent 链模式的选择，
/// 显示当前配置状态，并返回用户选择的模式
class AgentModeSelectionDialog extends StatelessWidget {
  /// 当前选中的单 Agent
  final AIAgent? currentAgent;

  /// 当前 Agent 链
  final List<AgentChainNode> agentChain;

  /// 是否为链模式
  final bool isChainMode;

  const AgentModeSelectionDialog({
    super.key,
    this.currentAgent,
    this.agentChain = const [],
    this.isChainMode = false,
  });

  /// 获取当前 Agent 配置的显示文本
  String _getCurrentAgentDisplayText() {
    if (!isChainMode && currentAgent != null) {
      return '当前: ${currentAgent!.name}';
    } else if (isChainMode && agentChain.isNotEmpty) {
      final chainLength = agentChain.length;
      // 显示前 3 个 agent 名称，超过则显示省略号
      final displayCount = chainLength > 3 ? 3 : chainLength;
      final agentNames = agentChain.take(displayCount).map((node) {
        // 这里需要从 agentId 获取 agent name，暂时先显示 ID
        // 在实际使用时，调用方应该传入包含 agent name 的信息
        return node.agentId;
      }).join(' → ');

      final suffix = chainLength > 3 ? '...' : '';
      return '当前 ($chainLength个): $agentNames$suffix';
    }
    return '未配置';
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentlySingleMode = !isChainMode && currentAgent != null;
    final isCurrentlyChainMode = isChainMode && agentChain.isNotEmpty;

    return SimpleDialog(
      title: const Text('选择配置模式'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'single'),
          child: ListTile(
            leading: Icon(
              isCurrentlySingleMode ? Icons.check_circle : Icons.smart_toy,
              color: isCurrentlySingleMode ? Colors.green : null,
            ),
            title: const Text('单 Agent 模式'),
            subtitle: Text(
              isCurrentlySingleMode
                  ? '${_getCurrentAgentDisplayText()} | 选择一个 Agent 进行对话'
                  : '选择一个 Agent 进行对话',
            ),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'chain'),
          child: ListTile(
            leading: Icon(
              isCurrentlyChainMode ? Icons.check_circle : Icons.link,
              color: isCurrentlyChainMode ? Colors.green : null,
            ),
            title: const Text('Agent 链模式'),
            subtitle: Text(
              isCurrentlyChainMode
                  ? '${_getCurrentAgentDisplayText()} | 配置多个 Agent 顺序执行'
                  : '配置多个 Agent 顺序执行',
            ),
          ),
        ),
      ],
    );
  }
}
