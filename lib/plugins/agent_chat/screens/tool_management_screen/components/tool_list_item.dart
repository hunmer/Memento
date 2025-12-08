import 'package:flutter/material.dart';
import 'package:Memento/plugins/agent_chat/models/tool_config.dart';
import 'package:Memento/plugins/agent_chat/services/tool_config_manager.dart';
import 'tool_editor_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/l10n/agent_chat_localizations.dart';

/// 工具列表项组件
class ToolListItem extends StatelessWidget {
  final String pluginId;
  final String toolId;
  final ToolConfig config;
  final VoidCallback onRefresh;
  final Function(String pluginId, String toolId, ToolConfig config)? onAddToChat;

  const ToolListItem({
    super.key,
    required this.pluginId,
    required this.toolId,
    required this.config,
    required this.onRefresh,
    this.onAddToChat,
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
      toastService.showToast('切换状态失败: $e');
    }
  }

  /// 编辑工具
  Future<void> _editTool(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => ToolEditorDialog(
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

        toastService.showToast('工具更新成功');
        onRefresh();
      } catch (e) {
        toastService.showToast('更新工具失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${pluginId}_$toolId'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // 弹出确认对话框
        return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AgentChatLocalizations.of(context)!.confirmDelete),
                content: Text(AgentChatLocalizations.of(context)!.confirmDeleteTool(toolId)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AgentChatLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AgentChatLocalizations.of(context)!.delete),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        try {
          await ToolConfigManager.instance.deleteTool(pluginId, toolId);
          toastService.showToast('工具已删除');
          onRefresh();
        } catch (e) {
          toastService.showToast('删除工具失败: $e');
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: Card(
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
              Text(config.title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                config.getBriefDescription(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              if (onAddToChat != null)
                IconButton(
                  icon: const Icon(Icons.add_comment, size: 20),
                  tooltip: '添加到聊天',
                  onPressed: () => onAddToChat!(pluginId, toolId, config),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              Switch(
                value: config.enabled,
                onChanged: (value) => _toggleEnabled(context, value),
              ),
            ],
          ),
          onTap: () => _editTool(context),
        ),
      ),
    );
  }
}
