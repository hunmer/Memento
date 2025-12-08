import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'agent_card.dart';

class AgentGridView extends StatelessWidget {
  final List<AIAgent> agents;

  const AgentGridView({
    super.key,
    required this.agents,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        return AgentCard(agent: agents[index]);
      },
    );
  }
}