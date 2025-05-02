import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/image_utils.dart';
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
              '服务商: ${agent.serviceProviderId}',
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
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(agent.avatarUrl),
        builder: (context, snapshot) {
          return SizedBox(
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getColorForServiceProvider(agent.serviceProviderId).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipOval(
                    child: agent.avatarUrl!.startsWith('http')
                        ? Image.network(
                            agent.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultIcon(),
                          )
                        : snapshot.hasData
                            ? Image.file(
                                File(snapshot.data!),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultIcon(),
                              )
                            : _buildDefaultIcon(),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    
    // 如果有自定义图标，使用自定义图标
    if (agent.icon != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: agent.iconColor ?? _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(
          agent.icon,
          size: 24,
          color: Colors.white,
        ),
      );
    }
    
    // 默认图标
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 24,
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
