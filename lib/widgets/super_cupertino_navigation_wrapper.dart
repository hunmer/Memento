import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  /// 搜索结果页面内容Widget
  /// 当搜索框聚焦或有内容时显示此Widget
  final Widget? searchBody;

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

  /// 返回按钮点击回调
  /// 如果提供此回调，在非移动端（桌面平台）将显示自定义返回按钮
  final VoidCallback? onLeadingPressed;

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
    this.searchPlaceholder = '', // 改为空字符串，通过国际化获取默认值
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchBody,
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
    this.filterLabels = const {}, // 改为空映射，通过国际化获取默认值
    this.onSearchFilterChanged,
    this.onLeadingPressed,
  });

  @override
  State<SuperCupertinoNavigationWrapper> createState() => _SuperCupertinoNavigationWrapperState();
}

class _SuperCupertinoNavigationWrapperState extends State<SuperCupertinoNavigationWrapper> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false; // 搜索状态：基于文本内容判断
  bool _isTextFieldFocused = false; // 焦点状态：跟踪输入框是否获得焦点
  final Map<String, bool> _searchFilters = {
    'activity': true,
    'tag': true,
    'comment': true,
  };

  /// 获取国际化文本
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 初始化搜索过滤器状态
    _searchFilters.addAll(widget.filterLabels.keys.where((key) => !_searchFilters.containsKey(key))
        .fold<Map<String, bool>>({}, (map, key) => map..[key] = true));

    // 监听搜索框内容变化 - 使用 setState 强制重建 UI
    _searchController.addListener(() {
      final hasText = _searchController.text.isNotEmpty;
      if (mounted) {
        setState(() {
          _isSearchFocused = hasText || _isTextFieldFocused;
        });
      }
    });

    // 监听焦点变化 - 使用 setState 强制重建 UI
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isTextFieldFocused = _searchFocusNode.hasFocus;
          // 更新搜索状态：文本存在或输入框获得焦点
          _isSearchFocused =
              _searchController.text.isNotEmpty || _isTextFieldFocused;
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

  /// 获取默认的搜索占位符
  String _getDefaultSearchPlaceholder() {
    return _localizations?.search ?? '搜索';
  }

  /// 获取默认的过滤器标签
  Map<String, String> _getDefaultFilterLabels() {
    final loc = _localizations;
    if (loc == null) {
      return {
        'activity': '活动',
        'tag': '标签',
        'comment': '注释',
      };
    }

    return {
      'activity': loc.activity,
      'tag': loc.tag,
      'comment': loc.comment,
    };
  }

  /// 构建搜索过滤器
  Widget _buildSearchFilter() {
    if (!widget.enableSearchFilter) {
      return const SizedBox.shrink();
    }

    // 获取过滤器标签（使用默认或自定义）
    final filterLabels = widget.filterLabels.isNotEmpty
        ? widget.filterLabels
        : _getDefaultFilterLabels();

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
          Text(
            _localizations?.searchScope ?? '搜索范围',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: filterLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final value = _searchFilters[key] ?? true;

                  // 简化过滤项：让点击直接触发更新，不影响焦点
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

  /// 获取显示用的标题文本
  String _getDisplayTitle() {
    // 如果启用大标题，使用 largeTitle
    if (widget.enableLargeTitle) {
      return widget.largeTitle;
    }

    // 如果没有启用大标题，尝试从 widget.title 中提取文本
    if (widget.title is Text) {
      final textWidget = widget.title as Text;
      return textWidget.data ?? '';
    }

    // 如果是其他类型的 Widget，使用 largeTitle 或空字符串
    return widget.largeTitle.isNotEmpty ? widget.largeTitle : '';
  }

  @override
  Widget build(BuildContext context) {
    // 根据搜索状态选择显示哪个body - 使用 setState 保证实时更新
    final shouldShowSearchBody = widget.enableSearchBar &&
                                  widget.searchBody != null &&
                                  _isSearchFocused;
    final currentBody = shouldShowSearchBody ? widget.searchBody! : widget.body;

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SuperScaffold(
        onCollapsed: widget.onCollapsed,
        stretch: widget.stretch,
        appBar: _buildSuperAppBar(),
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
            // 搜索过滤器 - 依赖 _isSearchFocused 状态
            if (widget.enableSearchFilter && _isSearchFocused)
              _buildSearchFilter(),
            // 过滤栏 - 只在非搜索状态下显示
            if (widget.enableFilterBar && widget.filterBarChild != null && !_isSearchFocused)
              Container(
                height: widget.filterBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.filterBarChild,
              ),
            // 主体内容 - 根据搜索状态切换
            Expanded(child: currentBody),
          ],
        ),
      ),
    );
  }

  /// 构建 SuperAppBar，根据 enableSearchBar 条件决定是否包含 searchBar
  SuperAppBar _buildSuperAppBar() {
    // 构建 searchBar，当 enableSearchBar 为 false 时传入 disabled 的 SuperSearchBar
    final searchBar =
        widget.enableSearchBar
            ? _buildSearchBar()
            : SuperSearchBar(
              enabled: false,
              scrollBehavior: SearchBarScrollBehavior.pinned,
              resultBehavior: SearchBarResultBehavior.neverVisible,
            );

    return SuperAppBar(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      leading: (Platform.isAndroid || Platform.isIOS)
          ? null
          : (widget.onLeadingPressed != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onLeadingPressed,
                )
              : null),
      title: widget.title,
      previousPageTitle: widget.previousPageTitle ?? _localizations?.back ?? "返回",
      actions: widget.actions != null && widget.actions!.isNotEmpty
          ? Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: widget.actions!,
            )
          : null,
      bottom: _buildBottomBar(),
      largeTitle: SuperLargeTitle(
        height: 50,
        enabled: widget.enableLargeTitle,
        largeTitle: _getDisplayTitle(),
        actions: widget.largeTitleActions,
      ),
      // 只有当启用搜索栏时才传递 searchBar 参数
      searchBar: searchBar,
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
  SuperSearchBar _buildSearchBar() {
    // 注意：此方法仅在 enableSearchBar=true 时被调用
    return SuperSearchBar(
      enabled: true,
      scrollBehavior: SearchBarScrollBehavior.pinned,
      resultBehavior: SearchBarResultBehavior.neverVisible,
      placeholderText: widget.searchPlaceholder.isNotEmpty
          ? widget.searchPlaceholder
          : _getDefaultSearchPlaceholder(),
      searchController: _searchController,
      onChanged: (value) {
        widget.onSearchChanged?.call(value);
        widget.onAdvancedSearchChanged?.call({'query': value});
        // onChanged 回调已经在 _searchController.addListener 中处理了
      },
      onSubmitted: widget.onSearchSubmitted,
    );
  }
}