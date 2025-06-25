import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:flutter/material.dart';
import '../l10n/openai_localizations.dart';
import '../openai_plugin.dart';
import '../controllers/tool_app_controller.dart';
import '../widgets/agent_list_view.dart';
import '../widgets/agent_grid_view.dart';
import '../widgets/tool_app_grid_view.dart';
import '../widgets/filter_dialog.dart';
import '../models/ai_agent.dart';
import 'agent_edit_screen.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AgentController _agentController;
  late ToolAppController _toolAppController;
  bool _isGridView = true;
  Set<String> _selectedProviders = {};
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _agentController = OpenAIPlugin.instance.controller;
    _toolAppController = ToolAppController();
    _agentController.addListener(_onAgentsChanged);
    _loadAgents();
  }

  @override
  void dispose() {
    _agentController.removeListener(_onAgentsChanged);
    _tabController.dispose();
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Agents Tab
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
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
          ),
          // Tools Tab
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
              title: Text(OpenAILocalizations.of(context).toolsTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // TODO
                  },
                ),
              ],
            ),
            body: _buildToolsBody(),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).primaryColor.withAlpha(25),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: OpenAILocalizations.of(context).agentsTab,
            ),
            Tab(
              icon: const Icon(Icons.build),
              text: OpenAILocalizations.of(context).toolsTab,
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildToolsBody() {
    return AnimatedBuilder(
      animation: _toolAppController,
      builder: (context, child) {
        if (_toolAppController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ToolAppGridView(apps: _toolAppController.apps);
      },
    );
  }
}
