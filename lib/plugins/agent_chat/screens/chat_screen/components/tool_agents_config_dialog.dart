import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';

/// 工具调用 Agent 配置对话框
/// 适用于单 Agent 和 Agent 链模式
class ToolAgentsConfigDialog extends StatefulWidget {
  final String? initialToolDetectionAgentId;
  final String? initialToolExecutionAgentId;
  final Function(String? toolDetectionAgentId, String? toolExecutionAgentId) onSave;

  const ToolAgentsConfigDialog({
    super.key,
    this.initialToolDetectionAgentId,
    this.initialToolExecutionAgentId,
    required this.onSave,
  });

  @override
  State<ToolAgentsConfigDialog> createState() => _ToolAgentsConfigDialogState();
}

class _ToolAgentsConfigDialogState extends State<ToolAgentsConfigDialog> {
  List<AIAgent> _availableAgents = [];
  bool _isLoading = true;
  String? _toolDetectionAgentId;
  String? _toolExecutionAgentId;

  @override
  void initState() {
    super.initState();
    _toolDetectionAgentId = widget.initialToolDetectionAgentId;
    _toolExecutionAgentId = widget.initialToolExecutionAgentId;
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        final agents = await openAIPlugin.controller.loadAgents();
        setState(() {
          _availableAgents = agents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载 Agent 列表失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.build_circle, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('工具调用 Agent 配置'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              width: 300,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '配置工具调用的两个阶段使用的专用 Agent。如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // 工具需求识别 Agent
                  DropdownButtonFormField<String>(
                    value: _toolDetectionAgentId,
                    decoration: const InputDecoration(
                      labelText: '工具需求识别 Agent（第一阶段）',
                      border: OutlineInputBorder(),
                      hintText: '未配置（使用默认 prompt）',
                      helperText: '用于识别用户需要使用的工具',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('未配置（使用默认 prompt）'),
                      ),
                      ..._availableAgents.map((agent) {
                        return DropdownMenuItem<String>(
                          value: agent.id,
                          child: Text(agent.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _toolDetectionAgentId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 工具执行 Agent
                  DropdownButtonFormField<String>(
                    value: _toolExecutionAgentId,
                    decoration: const InputDecoration(
                      labelText: '工具执行 Agent（第二阶段）',
                      border: OutlineInputBorder(),
                      hintText: '未配置（使用默认 prompt）',
                      helperText: '用于生成工具调用的 JavaScript 代码',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('未配置（使用默认 prompt）'),
                      ),
                      ..._availableAgents.map((agent) {
                        return DropdownMenuItem<String>(
                          value: agent.id,
                          child: Text(agent.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _toolExecutionAgentId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_toolDetectionAgentId, _toolExecutionAgentId);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
