import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/core/plugin_manager.dart';

class AgentListDrawer extends StatefulWidget {
  /// 当前已选择的智能体列表
  final List<Map<String, String>> selectedAgents;

  /// 当智能体选择发生变化时的回调
  final Function(List<Map<String, String>>) onAgentSelected;

  /// 可选的文本控制器，用于处理@符号等特殊情况
  final TextEditingController? textController;

  /// 是否允许多选
  final bool allowMultipleSelection;

  /// 自定义智能体过滤器
  final bool Function(AIAgent)? agentFilter;

  /// 可选的extra storage key，用于保存/加载额外的agents
  /// 如果提供，将显示tab切换器，允许添加和删除agents
  final String? extraStorageKey;

  const AgentListDrawer({
    super.key,
    required this.selectedAgents,
    required this.onAgentSelected,
    this.textController,
    this.allowMultipleSelection = true,
    this.agentFilter,
    this.extraStorageKey,
  });

  @override
  State<AgentListDrawer> createState() => _AgentListDrawerState();
}

class _AgentListDrawerState extends State<AgentListDrawer>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _selectedAgents;
  late TabController? _tabController;
  List<AIAgent> _extraStorageAgents = [];

  @override
  void initState() {
    super.initState();
    // 复制已选择的智能体列表，避免直接修改原始列表
    _selectedAgents = List.from(widget.selectedAgents);

    // 如果提供了extraStorageKey，初始化TabController并加载extra agents
    if (widget.extraStorageKey != null) {
      _tabController = TabController(length: 2, vsync: this);
      _loadExtraStorageAgents();
    } else {
      _tabController = null;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 加载extra storage agents
  Future<void> _loadExtraStorageAgents() async {
    if (widget.extraStorageKey == null) return;

    final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
    final agents =
        await plugin.controller.loadExtraStorageAgents(widget.extraStorageKey!);
    if (mounted) {
      setState(() {
        _extraStorageAgents = agents;
      });
    }
  }

  /// 添加新agent
  Future<void> _addNewAgent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentEditScreen(
          extraStorageKey: widget.extraStorageKey,
        ),
      ),
    );

    // 如果创建成功，重新加载agents
    if (result == true) {
      await _loadExtraStorageAgents();
    }
  }

  /// 删除extra agent
  Future<void> _deleteExtraAgent(String agentId) async {
    if (widget.extraStorageKey == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此Agent吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      await plugin.controller.deleteAgentFromExtraStorage(
        agentId,
        widget.extraStorageKey!,
      );
      await _loadExtraStorageAgents();
    }
  }

  // 检查智能体是否已被选中
  bool _isAgentSelected(String agentId) {
    return _selectedAgents.any((agent) => agent['id'] == agentId);
  }

  // 切换智能体选择状态
  void _toggleAgentSelection(Map<String, String> agentData) {
    setState(() {
      if (_isAgentSelected(agentData['id']!)) {
        _selectedAgents.removeWhere((agent) => agent['id'] == agentData['id']);
      } else {
        if (!widget.allowMultipleSelection) {
          // 单选模式下，清除之前的选择
          _selectedAgents.clear();
        }
        _selectedAgents.add(agentData);
      }
    });
  }

  // 处理智能体选择完成
  void _handleSelectionComplete() {
    // 调用选择回调
    widget.onAgentSelected(_selectedAgents);

    // 关闭抽屉并返回选中的 Agents
    Navigator.pop(context, _selectedAgents);

    // 如果提供了文本控制器，处理@符号
    if (widget.textController?.text.endsWith('@') ?? false) {
      final text = widget.textController!.text;
      widget.textController!.text = text.substring(0, text.length - 1);
    }
  }

  // 构建智能体图标
  Widget _buildAgentIcon(AIAgent agent) {
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(agent.avatarUrl),
        builder: (context, snapshot) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorForServiceProvider(
                  agent.serviceProviderId,
                ).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  agent.avatarUrl!.startsWith('http')
                      ? Image.network(
                        agent.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildDefaultIcon(agent),
                      )
                      : snapshot.hasData
                      ? Image.file(
                        File(snapshot.data!),
                        width: 40,
                        height: 40,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              agent.iconColor ??
              _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(agent.icon, size: 20, color: Colors.white),
      );
    }

    // 默认图标
    return _buildDefaultIcon(agent);
  }

  // 构建默认图标
  Widget _buildDefaultIcon(AIAgent agent) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
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

  /// 构建agent列表
  Widget _buildAgentList(List<AIAgent> agents, {bool showDeleteButton = false}) {
    // 应用过滤器（如果有）
    if (widget.agentFilter != null) {
      agents = agents.where(widget.agentFilter!).toList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        final agentData = {'id': agent.id, 'name': agent.name};
        final isSelected = _isAgentSelected(agent.id);

        return ListTile(
          leading: _buildAgentIcon(agent),
          title: Text(agent.name),
          subtitle: Text(agent.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDeleteButton)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteExtraAgent(agent.id),
                ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Icon(Icons.circle_outlined),
            ],
          ),
          onTap: () => _toggleAgentSelection(agentData),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度
    final screenHeight = MediaQuery.of(context).size.height;
    // 计算抽屉最大高度为屏幕高度的70%
    final maxDrawerHeight = screenHeight * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxDrawerHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.smart_toy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'openai_selectAgent'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // 如果有extraStorageKey，显示新增按钮
                if (widget.extraStorageKey != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: '新增Agent',
                    onPressed: _addNewAgent,
                  ),
              ],
            ),
          ),
          const Divider(),
          // 如果有extraStorageKey，显示TabBar
          if (widget.extraStorageKey != null) ...[
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '默认Agents'),
                Tab(text: '自定义Agents'),
              ],
            ),
            const Divider(),
          ],
          Flexible(
            child: widget.extraStorageKey != null
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      // 默认agents
                      FutureBuilder<List<AIAgent>>(
                        future: (PluginManager.instance
                                .getPlugin('openai') as OpenAIPlugin)
                            .controller
                            .loadAgents(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _buildAgentList(snapshot.data!);
                          } else if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('openai_errorReadingAgents'.tr),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                      // Extra storage agents
                      _buildAgentList(
                        _extraStorageAgents,
                        showDeleteButton: true,
                      ),
                    ],
                  )
                : FutureBuilder<List<AIAgent>>(
                    future: (PluginManager.instance
                            .getPlugin('openai') as OpenAIPlugin)
                        .controller
                        .loadAgents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildAgentList(snapshot.data!);
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('openai_errorReadingAgents'.tr),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('app_cancel'.tr),
                ),
                ElevatedButton(
                  onPressed:
                      _selectedAgents.isEmpty ? null : _handleSelectionComplete,
                  child: Text(
                    '${'app_select'.tr} (${_selectedAgents.length})',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
