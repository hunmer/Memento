import 'package:flutter/foundation.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../models/conversation.dart';
import '../../models/agent_chain_node.dart';
import '../../services/conversation_service.dart';
import 'shared/manager_context.dart';

/// Agent 管理器
///
/// 负责 Agent 的加载、切换和配置管理
/// 遵循单一职责原则 (SRP)
class AgentManager {
  final ManagerContext context;
  final ConversationService conversationService;

  /// 当前 Agent (单 agent 模式)
  AIAgent? _currentAgent;

  /// Agent 链 (链式模式)
  List<AIAgent>? _agentChain;

  /// 当前会话
  Conversation? _currentConversation;

  AgentManager({
    required this.context,
    required this.conversationService,
  });

  // ========== Getters ==========

  AIAgent? get currentAgent => _currentAgent;
  List<AIAgent> get agentChain => _agentChain ?? [];
  bool get isChainMode => _currentConversation?.isChainMode ?? false;
  Conversation? get currentConversation => _currentConversation;

  // ========== 核心方法 ==========

  /// 初始化 - 加载会话关联的 Agent
  Future<void> initialize(Conversation conversation) async {
    _currentConversation = conversation;

    if (conversation.isChainMode && conversation.agentChain != null) {
      // 链式模式 - 加载 Agent 链
      await _loadAgentChain(conversation.agentChain!);
    } else if (conversation.agentId != null) {
      // 单 Agent 模式
      await _loadAgentInBackground(conversation.agentId!);
    }
  }

  /// 更新当前会话引用
  void updateConversation(Conversation conversation) {
    _currentConversation = conversation;
  }

  /// 选择并加载 Agent (单 Agent 模式)
  Future<void> selectAgent(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);

        // 更新会话的 agentId
        final updatedConversation =
            _currentConversation!.copyWith(agentId: agentId);
        await conversationService.updateConversation(updatedConversation);

        // 更新本地引用
        _currentConversation = updatedConversation;

        context.notify();
        debugPrint('✅ Agent 选择成功: ${_currentAgent?.name}');
      }
    } catch (e) {
      debugPrint('❌ 加载 Agent 失败: $e');
      rethrow;
    }
  }

  /// 选择并配置 Agent 链 (链式模式)
  Future<void> selectAgentChain(List<AgentChainNode> chainNodes) async {
    try {
      // 加载所有 agent
      await _loadAgentChain(chainNodes);

      // 更新会话配置
      final updatedConversation = _currentConversation!.copyWith(
        agentChain: chainNodes,
        clearAgentChain: false,
      );
      await conversationService.updateConversation(updatedConversation);

      _currentConversation = updatedConversation;
      context.notify();

      debugPrint('✅ Agent 链配置成功，共 ${chainNodes.length} 个节点');
    } catch (e) {
      debugPrint('❌ 配置 Agent 链失败: $e');
      rethrow;
    }
  }

  /// 配置工具调用专用 Agent (适用于单 Agent 和 Agent 链模式)
  Future<void> configureToolAgents({
    String? toolDetectionAgentId,
    String? toolExecutionAgentId,
  }) async {
    try {
      final updatedConversation = _currentConversation!.copyWith(
        toolDetectionAgentId: toolDetectionAgentId,
        toolExecutionAgentId: toolExecutionAgentId,
      );
      await conversationService.updateConversation(updatedConversation);

      _currentConversation = updatedConversation;
      context.notify();

      debugPrint('✅ 工具 Agent 配置成功');
      if (toolDetectionAgentId != null) {
        debugPrint('  工具需求识别 Agent: $toolDetectionAgentId');
      } else {
        debugPrint('  工具需求识别：使用默认 prompt');
      }
      if (toolExecutionAgentId != null) {
        debugPrint('  工具执行 Agent: $toolExecutionAgentId');
      } else {
        debugPrint('  工具执行：使用默认 prompt');
      }
    } catch (e) {
      debugPrint('❌ 配置工具 Agent 失败: $e');
      rethrow;
    }
  }

  /// 切换回单 Agent 模式
  Future<void> switchToSingleAgent(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);
        _agentChain = null;

        final updatedConversation = _currentConversation!.copyWith(
          agentId: agentId,
          clearAgentChain: true, // 清除链配置
        );
        await conversationService.updateConversation(updatedConversation);

        _currentConversation = updatedConversation;
        context.notify();

        debugPrint('✅ 已切换到单 Agent 模式: ${_currentAgent?.name}');
      }
    } catch (e) {
      debugPrint('❌ 切换单 Agent 失败: $e');
      rethrow;
    }
  }

  /// 获取可用的 Agent 列表
  Future<List<AIAgent>> getAvailableAgents() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        return await openAIPlugin.controller.loadAgents();
      }
      return [];
    } catch (e) {
      debugPrint('❌ 获取 Agent 列表失败: $e');
      return [];
    }
  }

  /// 获取工具调用专用 Agent
  /// 如果配置了专用 Agent 则返回，否则返回 null
  Future<AIAgent?> getToolAgent(String? agentId) async {
    if (agentId == null) return null;

    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin == null) return null;

      return await openAIPlugin.controller.getAgent(agentId);
    } catch (e) {
      debugPrint('⚠️ 加载工具 Agent 失败: $e');
      return null;
    }
  }

  // ========== 私有方法 ==========

  /// 后台加载 Agent (不抛出异常)
  Future<void> _loadAgentInBackground(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);
        debugPrint('✅ Agent 加载成功: ${_currentAgent?.name} (ID: $agentId)');
        context.notify();
      } else {
        debugPrint('❌ OpenAI 插件未找到，无法加载 Agent');
      }
    } catch (e) {
      debugPrint('❌ 后台加载 Agent 失败: $e');
      // 加载失败不影响界面显示
    }
  }

  /// 加载 Agent 链
  Future<void> _loadAgentChain(List<AgentChainNode> chainNodes) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin == null) {
        debugPrint('❌ OpenAI 插件未找到');
        return;
      }

      _agentChain = [];
      // 按 order 排序
      final sortedNodes = List<AgentChainNode>.from(chainNodes)
        ..sort((a, b) => a.order.compareTo(b.order));

      for (final node in sortedNodes) {
        final agent = await openAIPlugin.controller.getAgent(node.agentId);
        if (agent != null) {
          _agentChain!.add(agent);
          debugPrint('✅ 加载 Agent 链节点 ${node.order}: ${agent.name}');
        } else {
          debugPrint('⚠️ Agent ${node.agentId} 未找到');
        }
      }

      // 设置当前 agent 为第一个
      if (_agentChain!.isNotEmpty) {
        _currentAgent = _agentChain!.first;
      }

      debugPrint('✅ Agent 链加载完成，共 ${_agentChain!.length} 个 agent');
      context.notify();
    } catch (e) {
      debugPrint('❌ 加载 Agent 链失败: $e');
    }
  }
}
