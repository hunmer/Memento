import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:Memento/plugins/openai/services/agent_marketplace_service.dart';
import 'package:Memento/plugins/openai/widgets/marketplace_agent_grid_view.dart';
import 'package:Memento/plugins/openai/widgets/marketplace_agent_list_view.dart';
import 'package:Memento/plugins/openai/widgets/filter_dialog.dart';

/// Agent 商场页面
/// 从远程服务器获取并展示可安装的 Agent
class AgentMarketplaceScreen extends StatefulWidget {
  final String? marketplaceUrl;

  const AgentMarketplaceScreen({super.key, this.marketplaceUrl});

  @override
  State<AgentMarketplaceScreen> createState() => _AgentMarketplaceScreenState();
}

class _AgentMarketplaceScreenState extends State<AgentMarketplaceScreen> {
  final AgentMarketplaceService _marketplaceService =
      AgentMarketplaceService();
  final AgentController _agentController = AgentController();

  bool _isGridView = true;
  Set<String> _selectedProviders = {};
  Set<String> _selectedTags = {};
  List<String> _allTags = [];

  // 搜索相关状态
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _searchFilters = {
    'name': true,
    'description': true,
    'tags': true,
  };
  String _searchQuery = '';

  // 商场数据
  List<AIAgent> _marketplaceAgents = [];
  List<AIAgent> _localAgents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMarketplaceData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载商场数据
  Future<void> _loadMarketplaceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 并行加载商场 Agent 和本地 Agent
      final results = await Future.wait([
        _marketplaceService.fetchMarketplaceAgents(url: widget.marketplaceUrl),
        _agentController.loadAgents(),
      ]);

      _marketplaceAgents = results[0] as List<AIAgent>;
      _localAgents = results[1] as List<AIAgent>;

      // 提取所有标签
      _allTags = _marketplaceAgents
          .expand((agent) => agent.tags)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  /// 刷新本地 Agent 列表（安装后调用）
  Future<void> _refreshLocalAgents() async {
    try {
      _localAgents = await _agentController.loadAgents();
      setState(() {});
    } catch (e) {
      // 静默失败，不影响用户体验
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
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

  /// 获取过滤后的 Agent 列表
  List<AIAgent> _getFilteredAgents() {
    return _marketplaceAgents.where((agent) {
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
        final tagsMatch =
            agent.tags.any((tag) => tag.toLowerCase().contains(query));

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

  /// 构建类别过滤器
  Widget _buildCategoryFilter() {
    if (_allTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'openai_tags'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _allTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: const Text('Agent 商场'),
      largeTitle: 'Agent 商场',
      body: _buildBody(),
      enableLargeTitle: false,
      automaticallyImplyLeading: true,

      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: 'openai_searchAgent'.tr,
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
          icon: const Icon(Icons.refresh),
          onPressed: _loadMarketplaceData,
          tooltip: '刷新',
        ),
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
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMarketplaceData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_marketplaceAgents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '商场暂无可用 Agent',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _isGridView
              ? MarketplaceAgentGridView(
                  marketplaceAgents: _getFilteredAgents(),
                  localAgents: _localAgents,
                  onAgentChanged: _refreshLocalAgents,
                )
              : MarketplaceAgentListView(
                  marketplaceAgents: _getFilteredAgents(),
                  localAgents: _localAgents,
                  onAgentChanged: _refreshLocalAgents,
                ),
        ),
      ],
    );
  }
}
