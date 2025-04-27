import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import '../screens/agent_edit_screen.dart';

class AgentListItem extends StatelessWidget {
  final AIAgent agent;

  const AgentListItem({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _buildAgentIcon(),
        title: Text(
          agent.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${agent.type}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            _buildTags(),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgentEditScreen(agent: agent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentIcon() {
    // 使用固定图标，因为我们的新模型没有icon字段
    return Icon(
      Icons.smart_toy,
      size: 40,
      color: _getColorForAgentType(agent.type),
    );
  }

  Color _getColorForAgentType(String type) {
    switch (type) {
      case 'Assistant':
        return Colors.blue;
      case 'Translator':
        return Colors.green;
      case 'Writer':
        return Colors.purple;
      case 'Analyst':
        return Colors.orange;
      case 'Developer':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          agent.tags.take(3).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(tag, style: const TextStyle(fontSize: 10)),
            );
          }).toList(),
    );
  }
}
