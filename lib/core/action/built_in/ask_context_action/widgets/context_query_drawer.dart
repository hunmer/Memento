import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'package:Memento/plugins/openai/widgets/agent_list_drawer.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_node.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/agent_mode_selection_dialog.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/agent_chain_config_dialog.dart';
import '../models/route_context.dart';

/// 上下文查询抽屉
///
/// 允许用户基于当前路由上下文向AI提问
class ContextQueryDrawer extends StatefulWidget {
  /// 路由上下文信息
  final RouteContext routeContext;

  const ContextQueryDrawer({
    super.key,
    required this.routeContext,
  });

  @override
  State<ContextQueryDrawer> createState() => _ContextQueryDrawerState();
}

class _ContextQueryDrawerState extends State<ContextQueryDrawer> {
  late TextEditingController _textController;

  // Agent 配置状态
  bool _isChainMode = false; // 是否为链模式
  AIAgent? _selectedAgent; // 单 Agent 模式选中的 Agent
  List<AgentChainNode> _agentChain = []; // Agent 链配置

  bool _isLoading = false;
  String _responseText = '';
  bool _hasResponse = false;

  @override
  void initState() {
    super.initState();
    // 初始化输入框为路由解释文本
    _textController =
        TextEditingController(text: widget.routeContext.description);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 显示 Agent 模式选择器
  Future<void> _showAgentModeSelector() async {
    final mode = await showDialog<String>(
      context: context,
      builder:
          (context) => AgentModeSelectionDialog(
            currentAgent: _selectedAgent,
            agentChain: _agentChain,
            isChainMode: _isChainMode,
          ),
    );

    if (mode == null || !mounted) return;

    if (mode == 'single') {
      await _showSingleAgentSelector();
    } else {
      await _showAgentChainConfig();
    }
  }

  /// 显示单 Agent 选择器
  Future<void> _showSingleAgentSelector() async {
    final result = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AgentListDrawer(
        selectedAgents: _selectedAgent != null
            ? [
                {'id': _selectedAgent!.id, 'name': _selectedAgent!.name}
              ]
            : [],
        onAgentSelected: (agents) {
              // AgentListDrawer 会自己关闭并返回结果
        },
        allowMultipleSelection: false,
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final plugin =
            PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
        final agent = await plugin.controller.getAgent(result.first['id']!);
        setState(() {
          _selectedAgent = agent;
          _isChainMode = false;
          _agentChain = [];
        });
      } catch (e) {
        Toast.error('加载AI助手失败: $e');
      }
    }
  }

  /// 显示 Agent 链配置对话框
  Future<void> _showAgentChainConfig() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AgentChainConfigDialog(
            initialChain: _agentChain.isNotEmpty ? _agentChain : null,
            onSave: (chain) {
              setState(() {
                _agentChain = chain;
                _isChainMode = true;
                _selectedAgent = null;
              });
            },
          ),
    );
  }

  /// 获取当前 Agent 配置的显示文本
  String _getAgentDisplayText() {
    if (_isChainMode && _agentChain.isNotEmpty) {
      return '链模式 (${_agentChain.length}个Agent)';
    } else if (!_isChainMode && _selectedAgent != null) {
      return _selectedAgent!.name;
    }
    return '未选择';
  }

  /// 发送查询
  Future<void> _sendQuery() async {
    // 验证 Agent 配置
    if (_isChainMode) {
      if (_agentChain.isEmpty) {
        Toast.show('请先配置 Agent 链');
        return;
      }

      // 链模式需要使用完整的聊天界面
      Toast.show('链模式功能需要使用聊天界面，当前仅支持单 Agent 查询');
      return;
    } else {
      if (_selectedAgent == null) {
        Toast.show('请先选择AI助手');
        return;
      }
    }

    // 验证输入
    final query = _textController.text.trim();
    if (query.isEmpty) {
      Toast.show('请输入问题');
      return;
    }

    // 单 Agent 模式使用简单的 RequestService 调用
    await _sendSingleAgentQuery(query);
  }

  /// 发送单 Agent 查询
  Future<void> _sendSingleAgentQuery(String query) async {
    // 重置状态
    setState(() {
      _isLoading = true;
      _hasResponse = false;
      _responseText = '';
    });

    try {
      await RequestService.streamResponse(
        agent: _selectedAgent!,
        prompt: query,
        onToken: (token) {
          if (mounted) {
            setState(() {
              _responseText += token;
              _hasResponse = true;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _responseText = '错误: $error';
              _hasResponse = true;
            });
            Toast.error('发送失败');
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        shouldCancel: () => !mounted,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _responseText = '发送失败: $e';
          _hasResponse = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Row(
                children: [
                  Icon(Icons.assistant, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '询问当前上下文',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(height: 24),

              // 路由信息展示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.routeContext.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Agent选择
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_isChainMode ? Icons.link : Icons.smart_toy),
                title: const Text('选择AI助手'),
                subtitle: Text(_getAgentDisplayText()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showAgentModeSelector,
              ),
              const Divider(),

              // 输入框
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: '您的问题',
                  hintText: '编辑您的问题...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 16),

              // 加载指示器
              if (_isLoading) const LinearProgressIndicator(),

              // 响应展示
              if (_hasResponse) ...[
                const SizedBox(height: 16),
                const Text('AI回复：',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(_responseText),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('app_cancel'.tr),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendQuery,
                    child: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
