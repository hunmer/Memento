import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';

class AgentListDrawer extends StatelessWidget {
  final List<Map<String, String>> selectedAgents;
  final Function(Map<String, String>) onAgentSelected;
  final TextEditingController textController;

  const AgentListDrawer({
    Key? key,
    required this.selectedAgents,
    required this.onAgentSelected,
    required this.textController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.smart_toy),
                const SizedBox(width: 8),
                Text('选择智能体', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder<List<AIAgent>>(
            future: AgentController().loadAgents(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final agents = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: agents.length,
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    return ListTile(
                      leading: const Icon(Icons.smart_toy),
                      title: Text(agent.name),
                      subtitle: Text(agent.description),
                      onTap: () {
                        final agentData = {'id': agent.id, 'name': agent.name};

                        onAgentSelected(agentData);
                        Navigator.pop(context);

                        // 删除输入框中的@符号
                        if (textController.text.endsWith('@')) {
                          textController.text = textController.text.substring(
                            0,
                            textController.text.length - 1,
                          );
                        }
                      },
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('加载智能体列表失败'),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
