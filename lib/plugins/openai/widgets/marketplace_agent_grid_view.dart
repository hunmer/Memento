import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/services/agent_marketplace_service.dart';
import 'marketplace_agent_card.dart';

/// 商场 Agent 网格视图
class MarketplaceAgentGridView extends StatelessWidget {
  final List<AIAgent> marketplaceAgents;
  final List<AIAgent> localAgents;
  final VoidCallback? onAgentChanged;

  const MarketplaceAgentGridView({
    super.key,
    required this.marketplaceAgents,
    required this.localAgents,
    this.onAgentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final marketplaceService = AgentMarketplaceService();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: marketplaceAgents.length,
      itemBuilder: (context, index) {
        final agent = marketplaceAgents[index];
        final status = marketplaceService.getAgentStatus(agent, localAgents);

        return MarketplaceAgentCard(
          agent: agent,
          isInstalled: status['installed'] ?? false,
          hasUpdate: status['updateAvailable'] ?? false,
          onAgentChanged: onAgentChanged,
        );
      },
    );
  }
}
