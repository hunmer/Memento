import 'package:flutter/material.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

/// Super Cupertino Navigation Bar 的封装组件
///
/// 提供了一个统一的界面配置，包括：
/// - 大标题 (Large Title)
/// - 搜索栏 (Search Bar)
/// - 底部栏 (Bottom Bar)
/// - 自定义主题和样式
class SuperCupertinoNavigationWrapper extends StatefulWidget {
  /// 导航栏标题
  final Widget title;

  /// 大标题
  final String largeTitle;

  /// 子 widget
  final Widget body;

  /// 是否启用大标题
  final bool enableLargeTitle;

  /// 是否启用搜索栏
  final bool enableSearchBar;

  /// 是否启用底部栏
  final bool enableBottomBar;

  /// 底部栏高度
  final double bottomBarHeight;

  /// 底部栏子 widget
  final Widget? bottomBarChild;

  /// 搜索栏占位符文本
  final String searchPlaceholder;

  /// 搜索栏回调函数
  final Function(String)? onSearchChanged;
  final Function(String)? onSearchSubmitted;

  /// 导航栏操作按钮
  final List<Widget>? actions;

  /// 大标题操作按钮
  final List<Widget>? largeTitleActions;

  /// 背景颜色
  final Color? backgroundColor;

  /// 是否自动显示返回按钮
  final bool automaticallyImplyLeading;

  /// 返回按钮标题
  final String? previousPageTitle;

  /// 折叠状态回调
  final Function(bool)? onCollapsed;

  /// 是否启用拉伸效果
  final bool stretch;

  /// ========== 过滤栏相关配置 ==========

  /// 是否启用过滤栏
  final bool enableFilterBar;

  /// 过滤栏高度
  final double filterBarHeight;

  /// 过滤栏内容Widget
  final Widget? filterBarChild;

  /// 过滤条件变更回调
  final Function(Map<String, dynamic>)? onFilterChanged;

  /// ========== 高级搜索相关配置 ==========

  /// 是否启用高级搜索
  final bool enableAdvancedSearch;

  /// 搜索条件筛选器Widget列表
  final List<Widget>? searchFilters;

  /// 高级搜索变更回调
  final Function(Map<String, dynamic>)? onAdvancedSearchChanged;

  /// ========== 搜索过滤器相关配置 ==========

  /// 是否启用搜索过滤器
  final bool enableSearchFilter;

  /// 搜索过滤器标签配置
  final Map<String, String> filterLabels;

  /// 搜索过滤器状态回调
  final Function(Map<String, bool>)? onSearchFilterChanged;

  const SuperCupertinoNavigationWrapper({
    super.key,
    required this.title,
    required this.body,
    this.largeTitle = '',
    this.enableLargeTitle = true,
    this.enableSearchBar = false,
    this.enableBottomBar = false,
    this.bottomBarHeight = 40,
    this.bottomBarChild,
    this.searchPlaceholder = '搜索',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.actions,
    this.largeTitleActions,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.previousPageTitle,
    this.onCollapsed,
    this.stretch = true,
    // 过滤栏参数
    this.enableFilterBar = false,
    this.filterBarHeight = 50,
    this.filterBarChild,
    this.onFilterChanged,
    // 高级搜索参数
    this.enableAdvancedSearch = false,
    this.searchFilters,
    this.onAdvancedSearchChanged,
    // 搜索过滤器参数
    this.enableSearchFilter = false,
    this.filterLabels = const {
      'activity': '活动',
      'tag': '标签',
      'comment': '注释',
    },
    this.onSearchFilterChanged,
  });

  @override
  State<SuperCupertinoNavigationWrapper> createState() => _SuperCupertinoNavigationWrapperState();
}

class _SuperCupertinoNavigationWrapperState extends State<SuperCupertinoNavigationWrapper> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  final Map<String, bool> _searchFilters = {
    'activity': true,
    'tag': true,
    'comment': true,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 初始化搜索过滤器状态
    _searchFilters.addAll(widget.filterLabels.keys.where((key) => !_searchFilters.containsKey(key))
        .fold<Map<String, bool>>({}, (map, key) => map..[key] = true));

    // 监听搜索框内容变化
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          // 当搜索框有内容时显示过滤器
          _isSearchFocused = _searchController.text.isNotEmpty;
        });
      }
    });
  }

  /// 更新搜索过滤器状态
  void _updateSearchFilter(String key, bool value) {
    setState(() {
      _searchFilters[key] = value;
    });
    widget.onSearchFilterChanged?.call(Map.from(_searchFilters));
  }

  /// 构建搜索过滤器
  Widget _buildSearchFilter() {
    if (!widget.enableSearchFilter || !_isSearchFocused) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text(
            '搜索范围',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: widget.filterLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final value = _searchFilters[key] ?? true;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: value,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        _updateSearchFilter(key, newValue);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SuperScaffold(
        onCollapsed: widget.onCollapsed,
        stretch: widget.stretch,
        appBar: SuperAppBar(
          backgroundColor: widget.backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: widget.title,
          previousPageTitle: widget.previousPageTitle ?? "返回",
          actions: widget.actions != null && widget.actions!.isNotEmpty
              ? Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: widget.actions!,
                )
              : null,
          bottom: _buildBottomBar(),
          searchBar: _buildSearchBar(),
          largeTitle: widget.enableLargeTitle
              ? SuperLargeTitle(
                  height: 50,
                  enabled: true,
                  largeTitle: widget.largeTitle,
                  actions: widget.largeTitleActions,
                )
              : null,
        ),
        body: Column(
          children: [
            // 高级搜索条件筛选器
            if (widget.enableAdvancedSearch && widget.searchFilters != null && widget.searchFilters!.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.searchFilters!,
                ),
              ),
            // 搜索过滤器
            if (widget.enableSearchFilter) _buildSearchFilter(),
            // 过滤栏
            if (widget.enableFilterBar && widget.filterBarChild != null)
              Container(
                height: widget.filterBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.filterBarChild,
              ),
            // 主体内容
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }

  /// 构建底部栏（保持向后兼容）
  SuperAppBarBottom? _buildBottomBar() {
    if (!widget.enableBottomBar) return null;
    return SuperAppBarBottom(
      enabled: true,
      height: widget.bottomBarHeight,
      color: Colors.transparent,
      child: widget.filterBarChild ?? const SizedBox(),
    );
  }

  /// 构建搜索栏
  SuperSearchBar? _buildSearchBar() {
    if (!widget.enableSearchBar) return null;
    return SuperSearchBar(
      enabled: true,
      scrollBehavior: SearchBarScrollBehavior.pinned,
      resultBehavior: SearchBarResultBehavior.neverVisible,
      placeholderText: widget.searchPlaceholder,
      searchController: _searchController,
      onChanged: (value) {
        widget.onSearchChanged?.call(value);
        widget.onAdvancedSearchChanged?.call({'query': value});
      },
      onSubmitted: widget.onSearchSubmitted,
    );
  }
}