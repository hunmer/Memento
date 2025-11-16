import 'package:flutter/material.dart';
import '../../../models/tool_config.dart';
import '../../../services/tool_config_manager.dart';
import 'tool_editor_dialog.dart';

/// 工具列表项组件
class ToolListItem extends StatelessWidget {
  final String pluginId;
  final String toolId;
  final ToolConfig config;
  final VoidCallback onRefresh;

  const ToolListItem({
    super.key,
    required this.pluginId,
    required this.toolId,
    required this.config,
    required this.onRefresh,
  });

  /// 切换启用状态
  Future<void> _toggleEnabled(BuildContext context, bool enabled) async {
    try {
      await ToolConfigManager.instance.toggleToolEnabled(
        pluginId,
        toolId,
        enabled,
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('切换状态失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 编辑工具
  Future<void> _editTool(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ToolEditorDialog(
        pluginId: pluginId,
        toolId: toolId,
        config: config,
        isNew: false,
      ),
    );

    if (result != null) {
      try {
        final updatedConfig = result['config'] as ToolConfig;
        await ToolConfigManager.instance.updateTool(
          pluginId,
          toolId,
          updatedConfig,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('工具更新成功'),
            backgroundColor: Colors.green,
          ),
        );
        onRefresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新工具失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 删除工具
  Future<void> _deleteTool(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除工具 "$toolId" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ToolConfigManager.instance.deleteTool(pluginId, toolId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('工具已删除'),
          backgroundColor: Colors.green,
        ),
      );
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除工具失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          config.enabled ? Icons.check_circle : Icons.cancel,
          color: config.enabled ? Colors.green : Colors.grey,
        ),
        title: Text(
          toolId,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: config.enabled ? null : TextDecoration.lineThrough,
            color: config.enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              config.title,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              config.getBriefDescription(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.input, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${config.parameters.length} 个参数',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.code, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${config.examples.length} 个示例',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 启用/禁用开关
            Switch(
              value: config.enabled,
              onChanged: (value) => _toggleEnabled(context, value),
            ),
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑',
              onPressed: () => _editTool(context),
            ),
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除',
              color: Colors.red,
              onPressed: () => _deleteTool(context),
            ),
          ],
        ),
      ),
    );
  }
}
