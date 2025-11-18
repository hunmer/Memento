import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:Memento/plugins/openai/controllers/analysis_preset_controller.dart';
import 'package:flutter/material.dart';
import '../l10n/openai_localizations.dart';
import '../openai_plugin.dart';
import '../widgets/agent_list_view.dart';
import '../widgets/agent_grid_view.dart';
import '../widgets/analysis_preset_list.dart';
import '../widgets/basic_info_dialog.dart';
import '../widgets/filter_dialog.dart';
import '../models/ai_agent.dart';
import '../models/analysis_preset.dart';
import 'agent_edit_screen.dart';
import 'preset_run_screen.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AgentController _agentController;
  late AnalysisPresetController _presetController;
  bool _isGridView = true;
  Set<String> _selectedProviders = {};
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _agentController = OpenAIPlugin.instance.controller;
    _presetController = AnalysisPresetController();
    _agentController.addListener(_onAgentsChanged);
    _loadAgents();
    _presetController.loadPresets();

    // 监听Tab切换以更新FAB显示
    _tabController.addListener(() {
      setState(() {}); // 触发rebuild以更新FAB显示
    });
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

  // 打开基础信息对话框（编辑预设）
  void _openPresetDialog(AnalysisPreset? preset) async {
    final result = await showDialog<AnalysisPreset>(
      context: context,
      builder: (context) => BasicInfoDialog(preset: preset),
    );

    // 对话框关闭后刷新列表
    if (result != null && mounted) {
      await _presetController.loadPresets();
    }
  }

  // 打开预设运行页面
  void _openPresetRunScreen(AnalysisPreset preset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetRunScreen(preset: preset),
      ),
    );

    // 页面返回后刷新列表
    if (mounted) {
      await _presetController.loadPresets();
    }
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
          // Analysis Tab (原Tools Tab)
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
              title: Text(OpenAILocalizations.of(context).analysisTab),
            ),
            body: AnalysisPresetList(
              controller: _presetController,
              onPresetTap: (preset) => _openPresetDialog(preset),
              onPresetRun: (preset) => _openPresetRunScreen(preset),
            ),
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
              icon: const Icon(Icons.analytics),
              text: OpenAILocalizations.of(context).analysisTab,
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
      floatingActionButton: _tabController.index == 1 // 只在分析Tab显示
          ? FloatingActionButton(
              onPressed: () => _openPresetDialog(null), // null表示新建预设
              tooltip: OpenAILocalizations.of(context).addPreset,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

}
