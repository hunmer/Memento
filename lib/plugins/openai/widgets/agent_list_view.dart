import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import 'agent_list_item.dart';

class AgentListView extends StatelessWidget {
  final List<AIAgent> agents;

  const AgentListView({
    Key? key,
    required this.agents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        return AgentListItem(agent: agents[index]);
      },
    );
  }
}