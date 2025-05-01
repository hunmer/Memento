import 'dart:io';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/ai_agent.dart';
import '../widgets/agent_list_drawer.dart';
import '../services/plugin_analysis_service.dart';
// 移除未使用的导入
import '../widgets/plugin_method_selection_dialog.dart';
import '../../../utils/image_utils.dart';
import '../l10n/openai_localizations.dart';

class PluginAnalysisDialog extends StatefulWidget {
  const PluginAnalysisDialog({super.key});

  @override
  State<PluginAnalysisDialog> createState() => _PluginAnalysisDialogState();
}

class _PluginAnalysisDialogState extends State<PluginAnalysisDialog> {
  // 构建智能体图标
  Widget _buildAgentIcon(AIAgent agent) {
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: PathUtils.toAbsolutePath(agent.avatarUrl),
        builder: (context, snapshot) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForServiceProvider(agent.serviceProviderId).withAlpha(128),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: agent.avatarUrl!.startsWith('http')
                ? Image.network(
                    agent.avatarUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIcon(agent),
                  )
                : snapshot.hasData
                    ? Image.file(
                        File(snapshot.data!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
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
      child: const Icon(
        Icons.smart_toy,
        size: 24,
        color: Colors.white,
      ),
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
  final PluginAnalysisService _service = PluginAnalysisService();
  AIAgent? _selectedAgent;
  String? _responseMessage;
  bool _isLoading = false;
  int _currentTabIndex = 0; // 当前选中的标签页索引

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // 打开智能体选择抽屉
  void _openAgentSelector() {
    final localizations = OpenAILocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentListDrawer(
        selectedAgents: _selectedAgent != null ? [{'id': _selectedAgent!.id, 'name': _selectedAgent!.name}] : const [],
        onAgentSelected: (selectedAgents) async {
          if (selectedAgents.isNotEmpty) {
            try {
              final agentController = AgentController();
              final selectedAgent = await agentController.getAgent(selectedAgents.first['id']!);
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
              final currentLocalizations = OpenAILocalizations.of(currentContext);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(content: Text('${currentLocalizations.loadingProviders} $e')),
              );
            }
          }
        },
        allowMultipleSelection: false,
        title: localizations.selectAgent,
        confirmButtonText: localizations.confirm,
      ),
    );
  }

  // 此方法不再需要，已经在按钮的onPressed中直接处理

  // 发送到智能体
  Future<void> _sendToAgent() async {
    final localizations = OpenAILocalizations.of(context);
    
    if (_selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseSelectAgentFirst)),
      );
      return;
    }

    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterPrompt)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    try {
      final response = await _service.sendToAgent(
        _selectedAgent!,
        _promptController.text,
      );

      setState(() {
        _responseMessage = response;
        _currentTabIndex = 1; // 自动切换到输出标签页
      });
    } catch (e) {
      setState(() {
        _responseMessage = '${localizations.sendingFailed}$e';
        _currentTabIndex = 1; // 即使出错也切换到输出标签页
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
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
                  final newText = currentText.isEmpty
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
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_responseMessage != null)
          Container(
            width: double.infinity,
            height: double.infinity, // 充满可用空间
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Markdown(
              data: _responseMessage!,
              selectable: true, // 允许选择文本
              padding: EdgeInsets.zero,
            ),
          )
        else
          Center(
            child: Text(
              localizations.noResponseYet,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
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
            DefaultTabController(
              length: 2,
              initialIndex: _currentTabIndex,
              child: Expanded(
                child: Column(
                  children: [
                  TabBar(
                    onTap: (index) {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    },
                    tabs: [
                      Tab(text: localizations.form),
                      Tab(text: localizations.output),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
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