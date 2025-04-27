import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../controllers/agent_controller.dart';
import '../widgets/agent_list_view.dart';
import '../widgets/agent_grid_view.dart';
import '../widgets/filter_dialog.dart';
import '../models/ai_agent.dart';
import 'agent_edit_screen.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({Key? key}) : super(key: key);

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AgentController _controller = AgentController();
  bool _isGridView = true;
  Set<String> _selectedTypes = {};
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    await _controller.loadAgents();
    setState(() {});
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            selectedTypes: _selectedTypes,
            selectedTags: _selectedTags,
            onApply: (types, tags) {
              setState(() {
                _selectedTypes = types;
                _selectedTags = tags;
              });
            },
          ),
    );
  }

  List<AIAgent> _getFilteredAgents() {
    return _controller.agents.where((agent) {
      bool typeMatch =
          _selectedTypes.isEmpty || _selectedTypes.contains(agent.type);
      bool tagMatch =
          _selectedTags.isEmpty ||
          agent.tags.any((tag) => _selectedTags.contains(tag));
      return typeMatch && tagMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: const Text('AI Assistant'),
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
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AgentEditScreen(),
                ),
              );
              if (result == true) {
                await _loadAgents();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Agents'), Tab(text: 'Statistics')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isGridView
              ? AgentGridView(agents: _getFilteredAgents())
              : AgentListView(agents: _getFilteredAgents()),
          const Center(child: Text('Statistics - Coming Soon')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
