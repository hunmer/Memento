import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:flutter/material.dart';
import '../l10n/openai_localizations.dart';
import '../openai_plugin.dart';
import '../widgets/agent_list_view.dart';
import '../widgets/agent_grid_view.dart';
import '../widgets/filter_dialog.dart';
import '../models/ai_agent.dart';
import 'agent_edit_screen.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  late AgentController _agentController;
  bool _isGridView = true;
  Set<String> _selectedProviders = {};
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _agentController = OpenAIPlugin.instance.controller;
    _agentController.addListener(_onAgentsChanged);
    _loadAgents();
  }

  @override
  void dispose() {
    _agentController.removeListener(_onAgentsChanged);
    super.dispose();
  }

  void _onAgentsChanged() {
    if (mounted) {
      setState(() {
        // 智能体列表已更新，UI需要刷新
      });
    }
  }

  Future<void> _loadAgents() async {
    await _agentController.loadAgents();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            selectedProviders: _selectedProviders,
            selectedTags: _selectedTags,
            onApply: (providers, tags) {
              setState(() {
                _selectedProviders = providers;
                _selectedTags = tags;
              });
            },
          ),
    );
  }

  List<AIAgent> _getFilteredAgents() {
    return _agentController.agents.where((agent) {
      bool providerMatch =
          _selectedProviders.isEmpty ||
          _selectedProviders.contains(agent.serviceProviderId);
      bool tagMatch =
          _selectedTags.isEmpty ||
          agent.tags.any((tag) => _selectedTags.contains(tag));
      return providerMatch && tagMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => PluginManager.toHomeScreen(context),
                ),
        title: Text(OpenAILocalizations.of(context).agentListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AgentEditScreen(),
                ),
              );
              // 不需要手动刷新，因为AgentController会通知变化
            },
          ),
        ],
      ),
      body:
          _isGridView
              ? AgentGridView(agents: _getFilteredAgents())
              : AgentListView(agents: _getFilteredAgents()),
    );
  }
}
