import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/llm_models.dart';

/// 工具调用 Agent 配置对话框
/// 适用于单 Agent 和 Agent 链模式
class ToolAgentsConfigDialog extends StatefulWidget {
  final ToolAgentConfig? initialToolDetectionConfig;
  final ToolAgentConfig? initialToolExecutionConfig;
  final Function(
    ToolAgentConfig? toolDetectionConfig,
    ToolAgentConfig? toolExecutionConfig,
  )
  onSave;

  const ToolAgentsConfigDialog({
    super.key,
    this.initialToolDetectionConfig,
    this.initialToolExecutionConfig,
    required this.onSave,
  });

  @override
  State<ToolAgentsConfigDialog> createState() => _ToolAgentsConfigDialogState();
}

class _ToolAgentsConfigDialogState extends State<ToolAgentsConfigDialog> {
  bool _isLoading = true;
  ToolAgentConfig? _toolDetectionConfig;
  ToolAgentConfig? _toolExecutionConfig;

  // 实际保存的服务商列表（Map 格式）
  List<Map<String, dynamic>> _savedProviders = [];

  @override
  void initState() {
    super.initState();
    _toolDetectionConfig = widget.initialToolDetectionConfig;
    _toolExecutionConfig = widget.initialToolExecutionConfig;
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        // 使用 UseCase 获取服务商列表
        final result = await openAIPlugin.useCase.getServiceProviders({});
        if (result.isSuccess && result.dataOrNull != null) {
          setState(() {
            _savedProviders = result.dataOrNull!;
            _isLoading = false;
          });
        } else {
          throw Exception(result.errorOrNull?.message ?? '未知错误');
        }
      }
    } catch (e) {
      print('加载服务商列表失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取指定服务商的所有模型
  List<LLMModel> _getModelsForProvider(String providerId) {
    for (final group in llmModelGroups) {
      if (group.id == providerId) {
        return group.models;
      }
    }
    return [];
  }

  /// 获取服务商显示名称
  String _getProviderLabel(String providerId) {
    for (final group in llmModelGroups) {
      if (group.id == providerId) {
        return group.name;
      }
    }
    return providerId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.build_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('工具调用 Agent 配置'),
        ],
      ),
      content:
          _isLoading
              ? const SizedBox(
                width: 400,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置工具调用的两个阶段使用的专用 Agent。选择服务商和模型后，将使用 ToolService 中预设的 prompt 临时创建 agent。如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    // ========== 工具需求识别配置 ==========
                    _buildAgentConfigSection(
                      context,
                      title: '工具需求识别（第一阶段）',
                      subtitle: '用于识别用户需要使用的工具，返回 needed_tools 列表',
                      config: _toolDetectionConfig,
                      onChanged: (config) {
                        setState(() {
                          _toolDetectionConfig = config;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // ========== 工具执行配置 ==========
                    _buildAgentConfigSection(
                      context,
                      title: '工具执行（第二阶段）',
                      subtitle: '用于生成工具调用的 JavaScript 代码',
                      config: _toolExecutionConfig,
                      onChanged: (config) {
                        setState(() {
                          _toolExecutionConfig = config;
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
            widget.onSave(_toolDetectionConfig, _toolExecutionConfig);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  /// 构建单个 Agent 配置区域
  Widget _buildAgentConfigSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required ToolAgentConfig? config,
    required Function(ToolAgentConfig?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),

          // 未配置状态
          if (config == null) ...[
            OutlinedButton.icon(
              onPressed: () {
                _showAgentConfigDialog(onChanged);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('配置服务商和模型'),
            ),
          ] else ...[
            // 已配置状态
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '服务商: ${_getProviderLabel(config.providerId)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '模型: ${config.modelName ?? config.modelId}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showAgentConfigDialog(onChanged, initialConfig: config);
                  },
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑配置',
                ),
                IconButton(
                  onPressed: () {
                    onChanged(null);
                  },
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '清除配置',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 显示 Agent 配置对话框
  void _showAgentConfigDialog(
    Function(ToolAgentConfig?) onChanged, {
    ToolAgentConfig? initialConfig,
  }) {
    String? selectedProviderId = initialConfig?.providerId;
    String? selectedModelId = initialConfig?.modelId;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(initialConfig == null ? '配置 Agent' : '编辑 Agent'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 选择服务商
                        DropdownButtonFormField<String>(
                          value: selectedProviderId,
                          decoration: const InputDecoration(
                            labelText: '服务商',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            ..._savedProviders.map((provider) {
                              return DropdownMenuItem<String>(
                                value: provider['id'] as String,
                                child: Text(provider['label'] as String),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedProviderId = value;
                              selectedModelId = null; // 重置模型选择
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // 选择模型
                        if (selectedProviderId != null) ...[
                          DropdownButtonFormField<String>(
                            value: selectedModelId,
                            decoration: const InputDecoration(
                              labelText: '模型',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ..._getModelsForProvider(selectedProviderId!).map((
                                model,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: model.id,
                                  child: Text(model.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedModelId = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedProviderId != null && selectedModelId != null) {
                    final model = _getModelsForProvider(
                      selectedProviderId!,
                    ).firstWhere((m) => m.id == selectedModelId);

                    onChanged(
                      ToolAgentConfig(
                        providerId: selectedProviderId!,
                        modelId: selectedModelId!,
                        modelName: model.name,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }
}
