import 'package:flutter/foundation.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';

class AgentController extends ChangeNotifier {
  static final AgentController _instance = AgentController._internal();
  factory AgentController() => _instance;
  AgentController._internal();

  // ========== 事件通知 ==========

  /// 触发AI助手事件
  void _notifyAgentEvent(String action, AIAgent agent) {
    final eventArgs = ItemEventArgs(
      eventName: 'openai_agent_$action',
      itemId: agent.id,
      title: agent.name,
      action: action,
    );
    EventManager.instance.broadcast('openai_agent_$action', eventArgs);
  }

  List<AIAgent> _agents = [];
  List<AIAgent> get agents => List.unmodifiable(_agents);

  // 临时agent列表(仅保存在内存中,不会保存到agents.json)
  final List<AIAgent> _temporaryAgents = [];
  List<AIAgent> get temporaryAgents => List.unmodifiable(_temporaryAgents);

  Future<List<AIAgent>> loadAgents() async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return [];

    try {
      final storage = plugin.storage;
      final data = await storage.read('${plugin.storageDir}/agents.json');
      if (data.isNotEmpty) {
        final List<dynamic> jsonList = (data['agents'] ?? []) as List<dynamic>;
        _agents =
            jsonList
                .map((item) => AIAgent.fromJson(item as Map<String, dynamic>))
                .toList();
      } else {
        // 如果文件为空，确保返回空列表
        _agents = [];
      }
      notifyListeners();
    } catch (e) {
      _agents = [];
      debugPrint('❌ 加载Agents失败: $e');
      notifyListeners();
    }
    return _agents;
  }

  Future<void> saveAgent(AIAgent agent) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // 调试日志：确认保存的Agent包含messages
    debugPrint('💾 保存Agent: ${agent.name}');
    debugPrint('📝 预设消息数量: ${agent.messages?.length ?? 0}');
    if (agent.messages != null && agent.messages!.isNotEmpty) {
      for (final msg in agent.messages!) {
        debugPrint(
          '  - ${msg.type}: ${msg.content.substring(0, msg.content.length > 20 ? 20 : msg.content.length)}${msg.content.length > 20 ? '...' : ''}',
        );
      }
    }

    // Load existing agents
    await loadAgents();

    // Update or add the agent
    final index = _agents.indexWhere((a) => a.id == agent.id);
    final bool isNewAgent = index < 0;

    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }

    // Save all agents
    final List<Map<String, dynamic>> agentsJson =
        _agents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/agents.json', {
      'agents': agentsJson,
    });

    // 通知监听器数据已更新
    notifyListeners();

    // 触发AI助手事件
    _notifyAgentEvent(isNewAgent ? 'added' : 'updated', agent);

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncOpenai();
  }

  Future<void> deleteAgent(String agentId) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // 获取要删除的agent用于事件
    final agentToDelete = _agents.firstWhere(
      (agent) => agent.id == agentId,
      orElse: () => throw Exception('Agent not found: $agentId'),
    );

    _agents.removeWhere((agent) => agent.id == agentId);
    final List<Map<String, dynamic>> agentsJson =
        _agents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/agents.json', {
      'agents': agentsJson,
    });

    // 通知监听器数据已更新
    notifyListeners();

    // 触发AI助手删除事件
    _notifyAgentEvent('deleted', agentToDelete);

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncOpenai();
  }

  Future<AIAgent?> getAgent(String agentId) async {
    await loadAgents();
    return _agents.firstWhere(
      (agent) => agent.id == agentId,
      orElse: () => throw Exception('Agent not found'),
    );
  }

  Future<List<String>> getAllTags() async {
    await loadAgents();
    final Set<String> uniqueTags = {};

    for (final agent in _agents) {
      uniqueTags.addAll(agent.tags);
    }

    return uniqueTags.toList()..sort();
  }

  List<String> getTypes() {
    return [
      'Assistant',
      'Translator',
      'Writer',
      'Analyst',
      'Developer',
      'Custom',
    ];
  }

  Future<void> addAgent(AIAgent agent) async {
    await saveAgent(agent);
  }

  Future<void> updateAgent(AIAgent agent) async {
    await saveAgent(agent);
  }

  /// 添加临时agent(仅保存在内存中,不会保存到agents.json)
  void addTemporaryAgent(AIAgent agent) {
    final index = _temporaryAgents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _temporaryAgents[index] = agent;
    } else {
      _temporaryAgents.add(agent);
    }
    notifyListeners();
  }

  /// 删除临时agent
  void deleteTemporaryAgent(String agentId) {
    _temporaryAgents.removeWhere((agent) => agent.id == agentId);
    notifyListeners();
  }

  /// 获取所有agents(包括临时agent)
  Future<List<AIAgent>> getAllAgents() async {
    await loadAgents();
    return [..._agents, ..._temporaryAgents];
  }

  /// 从extra storage加载agents
  Future<List<AIAgent>> loadExtraStorageAgents(String storageKey) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return [];

    try {
      final storage = plugin.storage;
      final data =
          await storage.read('${plugin.storageDir}/$storageKey.json');
      if (data.isNotEmpty) {
        final List<dynamic> jsonList = (data['agents'] ?? []) as List<dynamic>;
        return jsonList
            .map((item) => AIAgent.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('加载extra storage agents失败: $e');
    }
    return [];
  }

  /// 保存agent到extra storage
  Future<void> saveAgentToExtraStorage(
    AIAgent agent,
    String storageKey,
  ) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // 加载现有agents
    final existingAgents = await loadExtraStorageAgents(storageKey);

    // 更新或添加agent
    final index = existingAgents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      existingAgents[index] = agent;
    } else {
      existingAgents.add(agent);
    }

    // 保存
    final List<Map<String, dynamic>> agentsJson =
        existingAgents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/$storageKey.json', {
      'agents': agentsJson,
    });
    notifyListeners();
  }

  /// 从extra storage删除agent
  Future<void> deleteAgentFromExtraStorage(
    String agentId,
    String storageKey,
  ) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // 加载现有agents
    final existingAgents = await loadExtraStorageAgents(storageKey);

    // 删除agent
    existingAgents.removeWhere((agent) => agent.id == agentId);

    // 保存
    final List<Map<String, dynamic>> agentsJson =
        existingAgents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/$storageKey.json', {
      'agents': agentsJson,
    });
    notifyListeners();
  }
}
