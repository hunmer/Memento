import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';
import 'super_cupertino_navigation_wrapper/filter_models.dart';
import 'super_cupertino_navigation_wrapper/multi_filter_bar.dart';

/// Super Cupertino Navigation Bar 的封装组件
///
/// 提供了一个统一的界面配置，包括：
/// - 大标题 (Large Title)
/// - 搜索栏 (Search Bar)
/// - 底部栏 (Bottom Bar)
/// - 多条件过滤栏 (Multi Filter Bar)
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
  /// 当为 null 时,非移动端(桌面平台)默认不显示,移动端默认显示
  final bool? automaticallyImplyLeading;

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

  /// ========== 多条件过滤相关配置 ==========

  /// 是否启用多条件过滤
  final bool enableMultiFilter;

  /// 多条件过滤项列表
  final List<FilterItem>? multiFilterItems;

  /// 多条件过滤栏高度
  final double multiFilterBarHeight;

  /// 多条件过滤变更回调
  final ValueChanged<Map<String, dynamic>>? onMultiFilterChanged;

  /// 是否启用多条件过滤切换按钮
  /// 当为 true 时，会在 actions 中自动添加一个切换按钮
  /// 点击按钮可以显示/隐藏过滤栏，切换时会清空已有的过滤条件
  final bool multiFilterToggleable;

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
    this.automaticallyImplyLeading,
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
    // 多条件过滤参数
    this.enableMultiFilter = false,
    this.multiFilterItems,
    this.multiFilterBarHeight = 50,
    this.onMultiFilterChanged,
    this.multiFilterToggleable = true,
  });

  @override
  State<SuperCupertinoNavigationWrapper> createState() =>
      _SuperCupertinoNavigationWrapperState();
}

class _SuperCupertinoNavigationWrapperState
    extends State<SuperCupertinoNavigationWrapper> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false; // 搜索状态：基于文本内容判断
  bool _isTextFieldFocused = false; // 焦点状态：跟踪输入框是否获得焦点
  final Map<String, bool> _searchFilters = {
    'activity': true,
    'tag': true,
    'comment': true,
  };

  /// 多条件过滤状态
  late MultiFilterState _multiFilterState;

  /// 多条件过滤栏显示状态
  bool _isMultiFilterVisible = true;

  /// 获取国际化文本
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _multiFilterState.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 初始化多条件过滤状态
    _multiFilterState = MultiFilterState();
    // 初始化搜索过滤器状态
    _searchFilters.addAll(
      widget.filterLabels.keys
          .where((key) => !_searchFilters.containsKey(key))
          .fold<Map<String, bool>>({}, (map, key) => map..[key] = true),
    );

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
    return 'core_search'.tr;
  }

  /// 获取默认的过滤器标签
  Map<String, String> _getDefaultFilterLabels() {
    return {
      'activity': 'core_activity'.tr,
      'tag': 'core_tag'.tr,
      'comment': 'core_comment'.tr,
    };
  }

  /// 构建搜索过滤器
  Widget _buildSearchFilter() {
    if (!widget.enableSearchFilter) {
      return const SizedBox.shrink();
    }

    // 获取过滤器标签（使用默认或自定义）
    final filterLabels =
        widget.filterLabels.isNotEmpty
            ? widget.filterLabels
            : _getDefaultFilterLabels();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.12),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'core_searchScope'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children:
                filterLabels.entries.map((entry) {
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

  /// 退出搜索模式
  void _exitSearchMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchFocused = false;
      _isTextFieldFocused = false;
    });
    // 通知外部搜索已清空
    widget.onSearchChanged?.call('');
  }

  /// 检查是否为移动端
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    // 根据搜索状态选择显示哪个body - 使用 setState 保证实时更新
    final shouldShowSearchBody =
        widget.enableSearchBar && widget.searchBody != null && _isSearchFocused;
    final currentBody = shouldShowSearchBody ? widget.searchBody! : widget.body;

    // 移动端：搜索模式下拦截返回键
    return PopScope(
      canPop: !(_isMobile && _isSearchFocused),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isMobile && _isSearchFocused) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SuperScaffold(
        onCollapsed: widget.onCollapsed,
        stretch: widget.stretch,
        appBar: _buildSuperAppBar(),
        body: Column(
          children: [
            // 高级搜索条件筛选器
            if (widget.enableAdvancedSearch &&
                widget.searchFilters != null &&
                widget.searchFilters!.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.searchFilters!,
                ),
              ),
            // 搜索过滤器 - 依赖 _isSearchFocused 状态
            if (widget.enableSearchFilter && _isSearchFocused)
              _buildSearchFilter(),
            // 多条件过滤栏 - 只在非搜索状态下且可见时显示
            if (widget.enableMultiFilter &&
                widget.multiFilterItems != null &&
                widget.multiFilterItems!.isNotEmpty &&
                !_isSearchFocused &&
                _isMultiFilterVisible)
              MultiFilterBar(
                filterItems: widget.multiFilterItems!,
                filterState: _multiFilterState,
                onFilterChanged: widget.onMultiFilterChanged,
                height: widget.multiFilterBarHeight,
              ),
            // 过滤栏 - 只在非搜索状态下显示（保持向后兼容）
            if (widget.enableFilterBar &&
                widget.filterBarChild != null &&
                !_isSearchFocused &&
                !widget.enableMultiFilter)
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
      ),
    );
  }

  /// 构建 actions
  Widget? _buildActions() {
    final List<Widget> actionsList = [];

    // 如果启用了多条件过滤切换,将其添加到最前面
    if (widget.enableMultiFilter &&
        widget.multiFilterToggleable &&
        widget.multiFilterItems != null &&
        widget.multiFilterItems!.isNotEmpty) {
      actionsList.add(
        IconButton(
          icon: Icon(
            _isMultiFilterVisible ? Icons.filter_list : Icons.filter_list_off,
          ),
          tooltip: _isMultiFilterVisible ? '隐藏过滤' : '显示过滤',
          onPressed: _toggleMultiFilter,
        ),
      );
    }

    // 添加用户自定义的 actions
    if (widget.actions != null && widget.actions!.isNotEmpty) {
      actionsList.addAll(widget.actions!);
    }

    if (actionsList.isEmpty) {
      return null;
    }

    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actionsList,
    );
  }

  /// 切换多条件过滤栏显示状态
  void _toggleMultiFilter() {
    setState(() {
      _isMultiFilterVisible = !_isMultiFilterVisible;

      // 切换时清空所有过滤条件
      if (!_isMultiFilterVisible) {
        _multiFilterState.clearAll();
        // 通知外部过滤条件已清空
        widget.onMultiFilterChanged?.call({});
      }
    });
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

    // 当 automaticallyImplyLeading 为 null 时,根据平台自动设置
    // 非移动端(桌面平台)默认不显示返回按钮,移动端默认显示
    final bool effectiveAutomaticallyImplyLeading =
        widget.automaticallyImplyLeading ?? !(Platform.isAndroid || Platform.isIOS);

    return SuperAppBar(
      backgroundColor:
          widget.backgroundColor ??
          Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      automaticallyImplyLeading: effectiveAutomaticallyImplyLeading,
      leading:
          (Platform.isAndroid || Platform.isIOS)
              ? null
              : (widget.onLeadingPressed != null
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onLeadingPressed,
                  )
                  : null),
      title: widget.title,
      previousPageTitle: widget.previousPageTitle ?? 'core_back'.tr,
      actions: _buildActions(),
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
      color: Theme.of(context).colorScheme.surface,
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
      placeholderText:
          widget.searchPlaceholder.isNotEmpty
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
