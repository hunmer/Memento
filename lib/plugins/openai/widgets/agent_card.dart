import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import '../screens/agent_edit_screen.dart';

class AgentCard extends StatelessWidget {
  final AIAgent agent;

  const AgentCard({Key? key, required this.agent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgentEditScreen(agent: agent),
            ),
          );
        },
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
                    'Type: ${agent.type}',
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
    return Icon(
      Icons.smart_toy, // Default icon
      size: 64,
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
          agent.tags.take(2).map((tag) {
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
