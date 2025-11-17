import 'package:flutter/material.dart';
import '../../../models/tool_config.dart';
import 'tool_list_item.dart';

/// 插件分组展示组件
class PluginSection extends StatefulWidget {
  final String pluginId;
  final PluginToolSet toolSet;
  final List<String> visibleToolIds;
  final VoidCallback onRefresh;
  final Function(String pluginId, String toolId, ToolConfig config)? onAddToChat;

  const PluginSection({
    super.key,
    required this.pluginId,
    required this.toolSet,
    required this.visibleToolIds,
    required this.onRefresh,
    this.onAddToChat,
  });

  @override
  State<PluginSection> createState() => _PluginSectionState();
}

class _PluginSectionState extends State<PluginSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final enabledCount = widget.toolSet.enabledToolCount;
    final totalCount = widget.visibleToolIds.length;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // 插件标题栏
          ListTile(
            leading: Icon(
              _isExpanded ? Icons.folder_open : Icons.folder,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              widget.pluginId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '$enabledCount / $totalCount 个工具已启用',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

          // 工具列表
          if (_isExpanded)
            ...widget.visibleToolIds.map((toolId) {
              final config = widget.toolSet.tools[toolId];
              if (config == null) return const SizedBox.shrink();

              return ToolListItem(
                pluginId: widget.pluginId,
                toolId: toolId,
                config: config,
                onRefresh: widget.onRefresh,
                onAddToChat: widget.onAddToChat,
              );
            }),
        ],
      ),
    );
  }
}
