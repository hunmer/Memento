import 'dart:io';
import 'dart:async';
import 'package:Memento/core/plugin_manager.dart';

import '../services/request_service.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:flutter/material.dart';
import '../controllers/prompt_replacement_controller.dart';
import 'package:Memento/widgets/quill_viewer/index.dart';
import '../models/ai_agent.dart';
import '../widgets/agent_list_drawer.dart';
import '../widgets/plugin_method_selection_dialog.dart';
import '../../../utils/image_utils.dart';
import '../l10n/openai_localizations.dart';

class PluginAnalysisDialog extends StatefulWidget {
  const PluginAnalysisDialog({super.key});

  @override
  State<PluginAnalysisDialog> createState() => _PluginAnalysisDialogState();
}

class _PluginAnalysisDialogState extends State<PluginAnalysisDialog>
    with TickerProviderStateMixin {
  // 构建智能体图标
  Widget _buildAgentIcon(AIAgent agent) {
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(agent.avatarUrl),
        builder: (context, snapshot) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForServiceProvider(
                  agent.serviceProviderId,
                ).withAlpha(128),
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  agent.avatarUrl!.startsWith('http')
                      ? Image.network(
                        agent.avatarUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildDefaultIcon(agent),
                      )
                      : snapshot.hasData
                      ? Image.file(
                        File(snapshot.data!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildDefaultIcon(agent),
                      )
                      : _buildDefaultIcon(agent),
            ),
          );
        },
      );
    }

    // 如果有自定义图标，使用自定义图标
    if (agent.icon != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              agent.iconColor ??
              _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(agent.icon, size: 24, color: Colors.white),
      );
    }

    // 默认图标
    return _buildDefaultIcon(agent);
  }

  // 构建默认图标
  Widget _buildDefaultIcon(AIAgent agent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(Icons.smart_toy, size: 24, color: Colors.white),
    );
  }

  // 根据服务提供商获取颜色
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

  final TextEditingController _promptController = TextEditingController();
  AIAgent? _selectedAgent;
  String _responseMessage = ''; // 改为空字符串初始值，方便拼接
  bool _isLoading = false;
  late TabController _tabController;
  final StreamController<String> _streamController = StreamController<String>();
  final PromptReplacementController _promptReplacementController =
      PromptReplacementController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _streamController.close();
    super.dispose();
  }

  // 打开智能体选择抽屉
  void _openAgentSelector() {
    final localizations = OpenAILocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AgentListDrawer(
            selectedAgents:
                _selectedAgent != null
                    ? [
                      {'id': _selectedAgent!.id, 'name': _selectedAgent!.name},
                    ]
                    : const [],
            onAgentSelected: (selectedAgents) async {
              if (selectedAgents.isNotEmpty) {
                try {
                  final plugin =
                      PluginManager.instance.getPlugin('openai')
                          as OpenAIPlugin;
                  final agentController = plugin.controller;
                  final selectedAgent = await agentController.getAgent(
                    selectedAgents.first['id']!,
                  );
                  if (selectedAgent != null) {
                    setState(() {
                      _selectedAgent = selectedAgent;
                    });
                  }
                } catch (e) {
                  // 在异步操作后使用 BuildContext 前先检查 mounted
                  if (!mounted) return;

                  // 获取当前上下文，而不是使用闭包中的上下文
                  final currentContext = context;
                  final currentLocalizations = OpenAILocalizations.of(
                    currentContext,
                  );
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${currentLocalizations.loadingProviders} $e',
                      ),
                    ),
                  );
                }
              }
            },
            allowMultipleSelection: false,
          ),
    );
  }

  // 处理发送到智能体的请求
  Future<void> _sendToAgent() async {
    final localizations = OpenAILocalizations.of(context);

    // 验证输入
    if (_selectedAgent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.noAgentSelected)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 使用TabController切换到输出标签页
    _tabController.animateTo(1);

    try {
      // 清空之前的响应
      setState(() {
        _responseMessage = '';
      });

      // 在主线程中预处理所有方法替换
      final processedReplacements = await _promptReplacementController
          .preprocessPromptReplacements(_promptController.text);

      // 处理提示词替换
      final processedPrompt =
          PromptReplacementController.applyProcessedReplacements(
            _promptController.text,
            processedReplacements,
          );
      String raw = '';
      // 直接在当前上下文处理流式响应
      await RequestService.streamResponse(
        agent: _selectedAgent!,
        prompt: processedPrompt,
        onToken: (token) {
          if (!mounted) return;
          setState(() {
            // 处理思考内容，转换为Markdown格式
            raw += token;
            _responseMessage = RequestService.processThinkingContent(raw);
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _responseMessage += "\nERROR: $error";
            _isLoading = false;
          });
        },
        onComplete: () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
        },
        replacePrompt: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responseMessage += "\nERROR: $e";
        _isLoading = false;
      });
    }
  }

  // 在后台线程处理API请求的方法

  // 构建表单标签页
  Widget _buildFormTab(OpenAILocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 智能体选择器
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (_selectedAgent != null) ...[
                _buildAgentIcon(_selectedAgent!),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAgent!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAgent!.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    localizations.noAgentSelected,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _openAgentSelector,
                tooltip: localizations.selectAgentTooltip,
              ),
            ],
          ),
        ),

        // 提示词输入
        const SizedBox(height: 16),
        TextField(
          controller: _promptController,
          decoration: InputDecoration(
            labelText: localizations.prompt,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          minLines: 4,
        ),

        // 添加分析方法按钮
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await showDialog<Map<String, String>>(
                context: context,
                builder: (context) => const PluginMethodSelectionDialog(),
              );

              if (result != null && mounted) {
                setState(() {
                  // 在当前提示词的末尾添加 JSON 字符串
                  final currentText = _promptController.text;
                  final jsonString = result['jsonString'] ?? '';
                  final newText =
                      currentText.isEmpty
                          ? jsonString
                          : '$currentText\n$jsonString';
                  _promptController.text = newText;
                });
              }
            },
            icon: const Icon(Icons.add),
            label: Text(localizations.addAnalysisMethod),
          ),
        ),
      ],
    );
  }

  // 构建输出标签页
  Widget _buildOutputTab(OpenAILocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.agentResponse,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuillViewer(data: _responseMessage, selectable: true),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OpenAILocalizations.of(context);

    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = screenSize.height * 0.8; // 设置为屏幕高度的80%

    return Dialog(
      child: Container(
        width: 600,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max, // 改为max以充满容器高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(
                  localizations.pluginAnalysis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // 添加标签页
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: localizations.form),
                      Tab(text: localizations.output),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 表单标签页内容
                        _buildFormTab(localizations),

                        // 输出标签页内容
                        _buildOutputTab(localizations),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendToAgent,
                  icon: const Icon(Icons.send),
                  label: Text(localizations.sendRequest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
