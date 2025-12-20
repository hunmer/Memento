import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/services/agent_marketplace_service.dart';
import 'marketplace_agent_list_item.dart';

/// 商场 Agent 列表视图
class MarketplaceAgentListView extends StatelessWidget {
  final List<AIAgent> marketplaceAgents;
  final List<AIAgent> localAgents;
  final VoidCallback? onAgentChanged;

  const MarketplaceAgentListView({
    super.key,
    required this.marketplaceAgents,
    required this.localAgents,
    this.onAgentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final marketplaceService = AgentMarketplaceService();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: marketplaceAgents.length,
      itemBuilder: (context, index) {
        final agent = marketplaceAgents[index];
        final status = marketplaceService.getAgentStatus(agent, localAgents);

        return MarketplaceAgentListItem(
          agent: agent,
          isInstalled: status['installed'] ?? false,
          hasUpdate: status['updateAvailable'] ?? false,
          onAgentChanged: onAgentChanged,
        );
      },
    );
  }
}
