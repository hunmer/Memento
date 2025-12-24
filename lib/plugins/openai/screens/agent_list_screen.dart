import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_builders.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/widgets/agent_list_view.dart';
import 'package:Memento/plugins/openai/widgets/agent_grid_view.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/models/service_provider.dart';
import 'package:Memento/plugins/openai/controllers/provider_controller.dart';
import 'package:Memento/plugins/openai/screens/agent_marketplace_screen.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  late AgentController _agentController;
  final ProviderController _providerController = ProviderController();

  bool _isGridView = true;
  List<String> _allTags = []; // 所有可用的类别
  List<ServiceProvider> _allProviders = []; // 所有可用的服务商

  // 搜索相关状态
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _searchFilters = {
    'name': true,
    'description': true,
    'tags': true,
  };
  String _searchQuery = '';

  // MultiFilter 过滤值
  Map<String, dynamic> _multiFilterValues = {};

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
    // 加载所有类别
    _allTags = await _agentController.getAllTags();
    // 加载所有服务商
    _allProviders = await _providerController.getProviders();
    if (mounted) {
      setState(() {});
    }
  }

  void _openMarketplace() {
    NavigationHelper.push(context, const AgentMarketplaceScreen());
  }

  /// 处理 MultiFilter 变化
  void _onMultiFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      _multiFilterValues = filters;
    });
  }

  List<AIAgent> _getFilteredAgents() {
    return _agentController.agents.where((agent) {
      // 服务商筛选 - 从 MultiFilter 获取
      final selectedProviders =
          _multiFilterValues['providers'] as List<String>? ?? [];
      bool providerMatch =
          selectedProviders.isEmpty ||
          selectedProviders.contains(agent.serviceProviderId);

      // 标签筛选 - 从 MultiFilter 获取
      final selectedTags = _multiFilterValues['tags'] as List<String>? ?? [];
      bool tagMatch =
          selectedTags.isEmpty ||
          agent.tags.any((tag) => selectedTags.contains(tag));

      // 搜索筛选
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = agent.name.toLowerCase().contains(query);
        final descriptionMatch = agent.description.toLowerCase().contains(
          query,
        );
        final tagsMatch = agent.tags.any(
          (tag) => tag.toLowerCase().contains(query),
        );

        // 根据启用的搜索过滤器进行匹配
        final enabledFilters =
            _searchFilters.entries
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

  /// 构建 MultiFilter 过滤项
  List<FilterItem> _buildMultiFilterItems() {
    return [
      // 服务商筛选
      if (_allProviders.isNotEmpty)
        FilterItem(
          id: 'providers',
          title: 'openai_serviceProvider'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: _allProviders.map((p) => p.id).toList(),
            );
          },
          getBadge: FilterBuilders.tagsBadge,
          initialValue: <String>[],
        ),
      // 标签筛选
      if (_allTags.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: 'openai_tags'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: _allTags,
            );
          },
          getBadge: FilterBuilders.tagsBadge,
          initialValue: <String>[],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('openai_agentListTitle'.tr),
      largeTitle: 'openai_agentListTitle'.tr,
      body:
          _isGridView
              ? AgentGridView(agents: _getFilteredAgents())
              : AgentListView(agents: _getFilteredAgents()),
      enableLargeTitle: false,

      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: 'openai_searchAgent'.tr,
      onSearchChanged: _onSearchChanged,

      // 启用搜索过滤器
      enableSearchFilter: true,
      filterLabels: const {'name': '名称', 'description': '描述', 'tags': '标签'},
      onSearchFilterChanged: _onSearchFilterChanged,

      // 启用 MultiFilter
      enableMultiFilter: true,
      multiFilterItems: _buildMultiFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _onMultiFilterChanged,

      actions: [
        IconButton(
          icon: const Icon(Icons.store),
          onPressed: _openMarketplace,
          tooltip: '商场',
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
      ],
    );
  }
}
