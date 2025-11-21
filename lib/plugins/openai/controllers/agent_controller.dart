import 'package:flutter/foundation.dart';
import '../models/ai_agent.dart';
import '../../../core/plugin_manager.dart';
import '../../../core/services/plugin_widget_sync_helper.dart';

class AgentController extends ChangeNotifier {
  static final AgentController _instance = AgentController._internal();
  factory AgentController() => _instance;
  AgentController._internal();

  List<AIAgent> _agents = [];
  List<AIAgent> get agents => List.unmodifiable(_agents);

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
      notifyListeners();
    }
    return _agents;
  }

  Future<void> saveAgent(AIAgent agent) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // Load existing agents
    await loadAgents();

    // Update or add the agent
    final index = _agents.indexWhere((a) => a.id == agent.id);
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

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncOpenai();
  }

  Future<void> deleteAgent(String agentId) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    _agents.removeWhere((agent) => agent.id == agentId);
    final List<Map<String, dynamic>> agentsJson =
        _agents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/agents.json', {
      'agents': agentsJson,
    });

    // 通知监听器数据已更新
    notifyListeners();

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
}
