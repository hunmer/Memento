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

  /// 获取 Agent 链
  /// 单agent模式下返回包含当前agent的数组,统一处理逻辑
  List<AIAgent> get agentChain {
    // 如果是链式模式，返回完整的链
    if (_agentChain != null && _agentChain!.isNotEmpty) {
      return _agentChain!;
    }
    // 单agent模式：将当前agent包装成长度为1的链
    if (_currentAgent != null) {
      return [_currentAgent!];
    }
    // 都没有，返回空列表
    return [];
  }

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
    ToolAgentConfig? toolDetectionConfig,
    ToolAgentConfig? toolExecutionConfig,
  }) async {
    try {
      final updatedConversation = _currentConversation!.copyWith(
        toolDetectionConfig: toolDetectionConfig,
        toolExecutionConfig: toolExecutionConfig,
      );
      await conversationService.updateConversation(updatedConversation);

      _currentConversation = updatedConversation;
      context.notify();

      debugPrint('✅ 工具 Agent 配置成功');
      if (toolDetectionConfig != null) {
        debugPrint(
          '  工具需求识别: ${toolDetectionConfig.providerId}/${toolDetectionConfig.modelId}',
        );
      } else {
        debugPrint('  工具需求识别：使用默认 prompt');
      }
      if (toolExecutionConfig != null) {
        debugPrint(
          '  工具执行: ${toolExecutionConfig.providerId}/${toolExecutionConfig.modelId}',
        );
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

  /// 获取工具调用专用 Agent（临时创建）
  /// 如果配置了专用 Agent 则返回临时创建的 Agent，否则返回 null
  ///
  /// [config] - Agent 配置
  /// [enableFunctionCalling] - 是否启用工具调用（第一阶段需要，第二阶段不需要）
  Future<AIAgent?> getToolAgent(
    ToolAgentConfig? config, {
    bool enableFunctionCalling = false,
  }) async {
    if (config == null) return null;

    try {
      // 获取实际保存的服务商配置
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin == null) {
        throw Exception('OpenAI 插件未找到');
      }

      // 使用 UseCase 获取服务商列表
      final result = await openAIPlugin.useCase.getServiceProviders({});
      if (result.isFailure || result.dataOrNull == null) {
        throw Exception('获取服务商配置失败: ${result.errorOrNull?.message}');
      }

      // 查找匹配的服务商
      final providers = result.dataOrNull!;
      final provider = providers.firstWhere(
        (p) => p['id'] == config.providerId,
        orElse: () => throw Exception('未找到服务商: ${config.providerId}'),
      );

      // 临时创建一个 AIAgent 对象，使用真实的服务商配置
      // 使用占位符，RequestService 会根据阶段自动替换：
      // - toolDetectionConfig（第一阶段）：只替换 {tool_brief}，{tool_detail} 为空
      // - toolExecutionConfig（第二阶段）：只替换 {tool_detail}，{tool_brief} 为空
      final agent = AIAgent(
        id: 'temp_tool_${config.providerId}_${config.modelId}',
        name: '工具调用 Agent (${config.modelName ?? config.modelId})',
        description: '临时创建的工具调用专用 Agent',
        systemPrompt: '{tool_brief}{tool_detail}', // 两个阶段的占位符，根据 additionalPrompts 替换
        tags: const [],
        serviceProviderId: config.providerId,
        baseUrl: provider['baseUrl'] as String,
        headers: Map<String, String>.from(provider['headers'] as Map),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        model: config.modelId,
        temperature: 0.3,
        maxLength: 4096,
        enableFunctionCalling: enableFunctionCalling, // 根据阶段设置
        promptPresetId: null, // 不使用预设，使用原始 systemPrompt
      );

      return agent;
    } catch (e) {
      debugPrint('⚠️ 创建工具 Agent 失败: $e');
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
