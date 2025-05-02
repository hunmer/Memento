import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/core/plugin_manager.dart';

class AgentListDrawer extends StatefulWidget {
  /// 当前已选择的智能体列表
  final List<Map<String, String>> selectedAgents;

  /// 当智能体选择发生变化时的回调
  final Function(List<Map<String, String>>) onAgentSelected;

  /// 可选的文本控制器，用于处理@符号等特殊情况
  final TextEditingController? textController;

  /// 自定义标题
  final String? title;

  /// 自定义确认按钮文本
  final String? confirmButtonText;

  /// 自定义取消按钮文本
  final String? cancelButtonText;

  /// 是否允许多选
  final bool allowMultipleSelection;

  /// 自定义智能体过滤器
  final bool Function(AIAgent)? agentFilter;

  const AgentListDrawer({
    super.key,
    required this.selectedAgents,
    required this.onAgentSelected,
    this.textController,
    this.title = '选择智能体',
    this.confirmButtonText,
    this.cancelButtonText = '取消',
    this.allowMultipleSelection = true,
    this.agentFilter,
  });

  @override
  State<AgentListDrawer> createState() => _AgentListDrawerState();
}

class _AgentListDrawerState extends State<AgentListDrawer> {
  late List<Map<String, String>> _selectedAgents;

  @override
  void initState() {
    super.initState();
    // 复制已选择的智能体列表，避免直接修改原始列表
    _selectedAgents = List.from(widget.selectedAgents);
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
    widget.onAgentSelected(_selectedAgents);
    Navigator.pop(context);

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
                color: _getColorForServiceProvider(agent.serviceProviderId).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: agent.avatarUrl!.startsWith('http')
                ? Image.network(
                    agent.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIcon(agent),
                  )
                : snapshot.hasData
                    ? Image.file(
                        File(snapshot.data!),
                        width: 40,
                        height: 40,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: agent.iconColor ?? _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(
          agent.icon,
          size: 20,
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 20,
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(widget.title ?? '选择智能体',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder<List<AIAgent>>(
            future: (PluginManager.instance.getPlugin('openai') as OpenAIPlugin).controller.loadAgents(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var agents = snapshot.data!;
                
                // 应用过滤器（如果有）
                if (widget.agentFilter != null) {
                  agents = agents.where(widget.agentFilter!).toList();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: agents.length,
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    final agentData = {'id': agent.id, 'name': agent.name};
                    final isSelected = _isAgentSelected(agent.id);

                    return ListTile(
                      leading: _buildAgentIcon(agent),
                      title: Text(agent.name),
                      subtitle: Text(agent.description),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : const Icon(Icons.circle_outlined),
                      onTap: () => _toggleAgentSelection(agentData),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('加载智能体列表失败'),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              );
            },
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
                  child: Text(widget.cancelButtonText ?? '取消'),
                ),
                ElevatedButton(
                  onPressed: _selectedAgents.isEmpty ? null : _handleSelectionComplete,
                  child: Text(widget.confirmButtonText ??
                      '确认选择 (${_selectedAgents.length})'),
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