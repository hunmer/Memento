import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_node.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_preset.dart';
import 'package:Memento/plugins/agent_chat/services/agent_chain_preset_service.dart';
import 'package:Memento/core/storage/storage_manager.dart';

/// Agent 链配置对话框
class AgentChainConfigDialog extends StatefulWidget {
  final List<AgentChainNode>? initialChain;
  final Function(List<AgentChainNode>) onSave;

  const AgentChainConfigDialog({
    super.key,
    this.initialChain,
    required this.onSave,
  });

  @override
  State<AgentChainConfigDialog> createState() =>
      _AgentChainConfigDialogState();
}

class _AgentChainConfigDialogState extends State<AgentChainConfigDialog> {
  late List<AgentChainNode> _chain;
  List<AIAgent> _availableAgents = [];
  bool _isLoading = true;

  /// Agent 链预设服务
  late AgentChainPresetService _presetService;

  @override
  void initState() {
    super.initState();
    _chain = widget.initialChain != null
        ? List.from(widget.initialChain!)
        : [];

    // 初始化预设服务
    final storage = PluginManager.instance.storageManager!;
    _presetService = AgentChainPresetService(storage: storage);

    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        _availableAgents = await openAIPlugin.controller.loadAgents();
      }
    } catch (e) {
      debugPrint('加载Agent列表失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addNode() {
    if (_availableAgents.isEmpty) return;

    setState(() {
      _chain.add(AgentChainNode(
        agentId: _availableAgents.first.id,
        contextMode: AgentContextMode.conversationContext,
        order: _chain.length,
      ));
    });
  }

  void _removeNode(int index) {
    setState(() {
      _chain.removeAt(index);
      // 重新排序
      for (int i = 0; i < _chain.length; i++) {
        _chain[i] = _chain[i].copyWith(order: i);
      }
    });
  }

  void _moveUp(int index) {
    if (index == 0) return;
    setState(() {
      final temp = _chain[index];
      _chain[index] = _chain[index - 1].copyWith(order: index);
      _chain[index - 1] = temp.copyWith(order: index - 1);
    });
  }

  void _moveDown(int index) {
    if (index >= _chain.length - 1) return;
    setState(() {
      final temp = _chain[index];
      _chain[index] = _chain[index + 1].copyWith(order: index);
      _chain[index + 1] = temp.copyWith(order: index + 1);
    });
  }

  String _getContextModeDescription(AgentContextMode mode) {
    switch (mode) {
      case AgentContextMode.conversationContext:
        return '使用会话历史消息作为上下文（遵循上下文消息数量设置）';
      case AgentContextMode.chainContext:
        return '将前面所有 Agent 的输出作为上下文传递';
      case AgentContextMode.previousOnly:
        return '仅使用上一个 Agent 的输出作为输入';
    }
  }

  String _getContextModeLabel(AgentContextMode mode) {
    switch (mode) {
      case AgentContextMode.conversationContext:
        return '会话上下文';
      case AgentContextMode.chainContext:
        return '链式上下文（所有前序输出）';
      case AgentContextMode.previousOnly:
        return '仅上一步输出';
    }
  }

  /// 保存当前链为预设
  Future<void> _saveAsPreset() async {
    if (_chain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前链为空，无法保存')),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存为预设'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '预设名称',
                hintText: '输入预设名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '简要描述预设用途',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入预设名称')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      final description = descriptionController.text.trim();

      // 检查名称是否已存在
      if (_presetService.isNameExists(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预设名称 "$name" 已存在')),
        );
        return;
      }

      try {
        final preset = AgentChainPreset(
          name: name,
          description: description.isEmpty ? null : description,
          chain: List.from(_chain),
        );

        await _presetService.savePreset(preset);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('预设 "$name" 已保存')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      }
    }
  }

  /// 显示预设列表
  Future<void> _showPresetList() async {
    // 加载预设
    await _presetService.loadPresets();
    final presets = _presetService.presets;

    if (!mounted) return;

    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无保存的预设')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择预设'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return Card(
                child: ListTile(
                  title: Text(preset.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preset.description != null)
                        Text(preset.description!),
                      const SizedBox(height: 4),
                      Text(
                        '${preset.chain.length} 个 Agent',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除预设',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text('确定要删除预设 "${preset.name}" 吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await _deletePreset(preset.id);
                            Navigator.pop(context); // 关闭预设列表
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _applyPreset(preset.id);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 应用预设
  Future<void> _applyPreset(String presetId) async {
    final preset = _presetService.getPreset(presetId);
    if (preset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预设不存在')),
      );
      return;
    }

    setState(() {
      _chain = List.from(preset.chain);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已应用预设 "${preset.name}"')),
    );
  }

  /// 删除预设
  Future<void> _deletePreset(String presetId) async {
    try {
      await _presetService.deletePreset(presetId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('预设已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agent 链配置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: '加载预设',
                      onPressed: _showPresetList,
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: '保存为预设',
                      onPressed: _saveAsPreset,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 说明文字
            Text(
              '配置多个 Agent 按顺序执行，每个 Agent 可选择不同的上下文模式',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Agent 链列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chain.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_off,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('暂无 Agent 节点',
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount: _chain.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _chain.removeAt(oldIndex);
                              _chain.insert(newIndex, item);
                              // 更新 order
                              for (int i = 0; i < _chain.length; i++) {
                                _chain[i] = _chain[i].copyWith(order: i);
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final node = _chain[index];

                            return Card(
                              key: ValueKey(index),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 节点标题和操作按钮
                                    Row(
                                      children: [
                                        Icon(Icons.drag_handle,
                                            color: Colors.grey[400]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '步骤 ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward,
                                              size: 20),
                                          onPressed: index > 0
                                              ? () => _moveUp(index)
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_downward,
                                              size: 20),
                                          onPressed: index < _chain.length - 1
                                              ? () => _moveDown(index)
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          onPressed: () => _removeNode(index),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Agent 选择器
                                    DropdownButtonFormField<String>(
                                      value: node.agentId,
                                      decoration: const InputDecoration(
                                        labelText: 'Agent',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _availableAgents.map((agent) {
                                        return DropdownMenuItem(
                                          value: agent.id,
                                          child: Text(agent.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _chain[index] = _chain[index]
                                                .copyWith(agentId: value);
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // 上下文模式选择器
                                    DropdownButtonFormField<AgentContextMode>(
                                      value: node.contextMode,
                                      decoration: const InputDecoration(
                                        labelText: '上下文模式',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: AgentContextMode.values.map((mode) {
                                        return DropdownMenuItem(
                                          value: mode,
                                          child: Text(_getContextModeLabel(mode)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _chain[index] = _chain[index]
                                                .copyWith(contextMode: value);
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // 上下文模式说明
                                    Text(
                                      _getContextModeDescription(node.contextMode),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 16),

            // 底部按钮
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addNode,
                  icon: const Icon(Icons.add),
                  label: const Text('添加 Agent'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _chain.isEmpty
                      ? null
                      : () {
                          widget.onSave(_chain);
                          Navigator.pop(context);
                        },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
