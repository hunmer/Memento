import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import 'agent_card.dart';

class AgentGridView extends StatelessWidget {
  final List<AIAgent> agents;

  const AgentGridView({
    Key? key,
    required this.agents,
  }) : super(key: key);

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