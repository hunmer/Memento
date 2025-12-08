import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';

/// 添加小组件对话框
class AddWidgetDialog extends StatefulWidget {
  /// 可选的文件夹ID，如果提供则将组件添加到该文件夹
  final String? folderId;

  const AddWidgetDialog({super.key, this.folderId});

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<HomeWidget>> _widgetsByCategory = {};
  List<String> _categories = [];

  // 搜索和筛选状态
  String _searchQuery = '';
  final Set<HomeWidgetSize> _selectedSizes = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 获取所有小组件并按分类分组
    _widgetsByCategory = HomeWidgetRegistry().getWidgetsByCategory();
    _categories = _widgetsByCategory.keys.toList()..sort();

    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 检查是否有活动的筛选条件
  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _selectedSizes.isNotEmpty;

  /// 获取所有组件的扁平列表
  List<HomeWidget> get _allWidgets {
    return _widgetsByCategory.values.expand((list) => list).toList();
  }

  /// 获取过滤后的组件列表
  List<HomeWidget> get _filteredWidgets {
    if (!_hasActiveFilters) return _allWidgets;

    return _allWidgets.where((widget) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = widget.name.toLowerCase().contains(query);
        final matchesDescription =
            widget.description?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesDescription) return false;
      }

      // 尺寸过滤
      if (_selectedSizes.isNotEmpty) {
        final hasMatchingSize = widget.supportedSizes
            .any((size) => _selectedSizes.contains(size));
        if (!hasMatchingSize) return false;
      }

      return true;
    }).toList();
  }

  /// 切换尺寸筛选
  void _toggleSizeFilter(HomeWidgetSize size) {
    setState(() {
      if (_selectedSizes.contains(size)) {
        _selectedSizes.remove(size);
      } else {
        _selectedSizes.add(size);
      }
    });
  }

  /// 清除所有筛选
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedSizes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = screenSize.height * 0.8;
    // 在小屏幕下使用全宽，否则限制为500
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 500.0;

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Scaffold(
          appBar: AppBar(
            title: Text(ScreensLocalizations.of(context)!.addWidget),
            automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            bottom: _categories.isNotEmpty && !_hasActiveFilters
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: _categories
                        .map((category) => Tab(text: category))
                        .toList(),
                  )
                : null,
          ),
          body: _categories.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 搜索框和筛选器
                    _buildFilterBar(),

                    // 内容区域
                    Expanded(
                      child: _hasActiveFilters
                          ? _buildFilteredView()
                          : TabBarView(
                              controller: _tabController,
                              children: _categories
                                  .map((category) => _buildCategoryView(
                                      _widgetsByCategory[category]!))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 构建筛选栏（搜索框 + 尺寸筛选）
  Widget _buildFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索组件...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // 尺寸筛选器
          Row(
            children: [
              Text(
                '尺寸：',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSizeFilterChip(HomeWidgetSize.small, '1×1'),
                    _buildSizeFilterChip(HomeWidgetSize.medium, '2×1'),
                    _buildSizeFilterChip(HomeWidgetSize.large, '2×2'),
                  ],
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(ScreensLocalizations.of(context)!.clear),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建尺寸筛选芯片
  Widget _buildSizeFilterChip(HomeWidgetSize size, String label) {
    final isSelected = _selectedSizes.contains(size);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleSizeFilter(size),
      showCheckmark: true,
    );
  }

  /// 构建过滤后的视图
  Widget _buildFilteredView() {
    final filteredWidgets = _filteredWidgets;

    if (filteredWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的组件',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: Text(ScreensLocalizations.of(context)!.clearFilterConditions),
            ),
          ],
        ),
      );
    }

    return _buildCategoryView(filteredWidgets);
  }

  /// 构建分类视图
  Widget _buildCategoryView(List<HomeWidget> widgets) {
    // 根据屏幕宽度动态调整列数和宽高比
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400 ? 1 : 2;
    final childAspectRatio = screenWidth < 400 ? 1.2 : 0.85;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => _buildWidgetPreviewCard(widgets[index]),
    );
  }

  /// 构建小组件预览卡片
  Widget _buildWidgetPreviewCard(HomeWidget widget) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addWidget(widget),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标和标题
                Container(
                  padding: const EdgeInsets.all(16),
                  color: widget.color?.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      Icon(
                        widget.icon,
                        size: 48,
                        color: widget.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 描述文本
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: widget.description != null
                        ? Text(
                            widget.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),

            // 尺寸标签 - 右上角
            Positioned(
              top: 4,
              right: 4,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.supportedSizes
                    .map((size) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${size.width}×${size.height}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加小组件
  void _addWidget(HomeWidget widget) {
    final layoutManager = HomeLayoutManager();

    // 创建小组件实例
    final widgetItem = HomeWidgetItem(
      id: layoutManager.generateId(),
      widgetId: widget.id,
      size: widget.defaultSize,
    );

    // 添加到布局或文件夹
    if (this.widget.folderId != null) {
      // 添加到文件夹
      layoutManager.addItemToFolder(widgetItem, this.widget.folderId!);
    } else {
      // 添加到主页
      layoutManager.addItem(widgetItem);
    }

    // 关闭对话框
    Navigator.of(context).pop();

    // 显示提示
    final location = this.widget.folderId != null ? '文件夹' : '主页';
    Toast.success('已添加 ${widget.name} 到$location');
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '没有可用的小组件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}
