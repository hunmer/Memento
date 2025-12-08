import 'dart:io' show Platform;
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/widgets/agent_list_view.dart';
import 'package:Memento/plugins/openai/widgets/agent_grid_view.dart';
import 'package:Memento/plugins/openai/widgets/filter_dialog.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
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

  // 搜索相关状态
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _searchFilters = {
    'name': true,
    'description': true,
    'tags': true,
  };
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  void _onAgentsChanged() {
    if (mounted) {
      setState(() {
        // 智能体列表已更新，UI需要刷新
      });
    }
  }

  /// 处理搜索查询变化
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// 处理搜索过滤器变化
  void _onSearchFilterChanged(Map<String, bool> filters) {
    setState(() {
      _searchFilters.addAll(filters);
    });
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
      // 服务商筛选
      bool providerMatch =
          _selectedProviders.isEmpty ||
          _selectedProviders.contains(agent.serviceProviderId);

      // 标签筛选
      bool tagMatch =
          _selectedTags.isEmpty ||
          agent.tags.any((tag) => _selectedTags.contains(tag));

      // 搜索筛选
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = agent.name.toLowerCase().contains(query);
        final descriptionMatch = agent.description.toLowerCase().contains(query);
        final tagsMatch = agent.tags.any((tag) =>
            tag.toLowerCase().contains(query));

        // 根据启用的搜索过滤器进行匹配
        final enabledFilters = _searchFilters.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

        final matches = <bool>[];
        if (enabledFilters.contains('name')) {
          matches.add(nameMatch);
        }
        if (enabledFilters.contains('description')) {
          matches.add(descriptionMatch);
        }
        if (enabledFilters.contains('tags')) {
          matches.add(tagsMatch);
        }

        // 如果有启用的过滤器，只要有一个匹配就算匹配
        searchMatch = matches.isEmpty ? true : matches.any((match) => match);
      }

      return providerMatch && tagMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text(OpenAILocalizations.of(context).agentListTitle),
      largeTitle: OpenAILocalizations.of(context).agentListTitle,
      body: _isGridView
          ? AgentGridView(agents: _getFilteredAgents())
          : AgentListView(agents: _getFilteredAgents()),
      enableLargeTitle: false,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),

      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: '搜索智能体',
      onSearchChanged: _onSearchChanged,

      // 启用搜索过滤器
      enableSearchFilter: true,
      filterLabels: const {
        'name': '名称',
        'description': '描述',
        'tags': '标签',
      },
      onSearchFilterChanged: _onSearchFilterChanged,

      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: '筛选',
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: '切换视图',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            await NavigationHelper.push<bool>(
              context,
              const AgentEditScreen(),
            );
            // 不需要手动刷新，因为AgentController会通知变化
          },
          tooltip: '添加助手',
        ),
      ],
    );
  }
}
