import 'dart:convert';
import '../models/ai_agent.dart';
import '../../../core/plugin_manager.dart';

class AgentController {
  List<AIAgent> agents = [];

  Future<List<AIAgent>> loadAgents() async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return [];

    try {
      final storage = plugin.storage;
      final data = await storage.read('${plugin.storageDir}/agents.json');
      if (data.isNotEmpty) {
        final List<dynamic> jsonList = (data['agents'] ?? []) as List<dynamic>;
        agents =
            jsonList
                .map((item) => AIAgent.fromJson(item as Map<String, dynamic>))
                .toList();
      } else {
        // 如果文件为空，确保返回空列表
        agents = [];
      }
    } catch (e) {
      agents = [];
    }
    return agents;
  }

  Future<void> saveAgent(AIAgent agent) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // Load existing agents
    await loadAgents();

    // Update or add the agent
    final index = agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      agents[index] = agent;
    } else {
      agents.add(agent);
    }

    // Save all agents
    final List<Map<String, dynamic>> agentsJson =
        agents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/agents.json', {
      'agents': agentsJson,
    });
  }

  Future<void> deleteAgent(String agentId) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    agents.removeWhere((agent) => agent.id == agentId);
    final List<Map<String, dynamic>> agentsJson =
        agents.map((a) => a.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/agents.json', {
      'agents': agentsJson,
    });
  }

  Future<AIAgent?> getAgent(String agentId) async {
    await loadAgents();
    return agents.firstWhere(
      (agent) => agent.id == agentId,
      orElse: () => throw Exception('Agent not found'),
    );
  }

  Future<List<String>> getAllTags() async {
    await loadAgents();
    final Set<String> uniqueTags = {};

    for (final agent in agents) {
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
