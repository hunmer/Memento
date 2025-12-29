import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';

/// 添加小组件对话框 - 使用 SuperCupertinoNavigationWrapper 重构版本
class AddWidgetDialog extends StatefulWidget {
  /// 可选的文件夹ID，如果提供则将组件添加到该文件夹
  final String? folderId;

  const AddWidgetDialog({super.key, this.folderId});

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  Map<String, List<HomeWidget>> _widgetsByCategory = {};
  List<String> _categories = [];

  // 搜索查询状态
  String _searchQuery = '';

  // 过滤条件值（从 onMultiFilterChanged 回调获取）
  Map<String, dynamic> _filterValues = {};

  @override
  void initState() {
    super.initState();

    // 获取所有小组件并按分类分组
    _widgetsByCategory = HomeWidgetRegistry().getWidgetsByCategory();
    _categories = _widgetsByCategory.keys.toList()..sort();
  }

  /// 获取所有组件的扁平列表
  List<HomeWidget> get _allWidgets {
    return _widgetsByCategory.values.expand((list) => list).toList();
  }

  /// 获取过滤后的组件列表
  List<HomeWidget> _getFilteredWidgets() {
    var widgets = _allWidgets;

    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      widgets = widgets.where((widget) {
        final matchesName = widget.name.toLowerCase().contains(query);
        final matchesDescription =
            widget.description?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesDescription;
      }).toList();
    }

    // 应用分类过滤（从 _filterValues 中获取）
    final selectedCategory = _filterValues['category'] as String?;
    if (selectedCategory != null &&
        selectedCategory.isNotEmpty &&
        selectedCategory != '全部分类') {
      widgets = widgets.where((w) => w.category == selectedCategory).toList();
    }

    // 应用尺寸过滤（从 _filterValues 中获取）
    final selectedSizes = _filterValues['sizes'] as List<String>?;
    if (selectedSizes != null && selectedSizes.isNotEmpty) {
      widgets = widgets.where((widget) {
        return widget.supportedSizes.any((size) {
          final sizeKey = '${size.width}×${size.height}';
          return selectedSizes.contains(sizeKey);
        });
      }).toList();
    }

    return widgets;
  }

  /// 构建分类过滤器
  List<FilterItem> _buildFilterItems() {
    return [
      // 分类过滤器
      FilterItem(
        id: 'category',
        title: '分类',
        type: FilterType.tagsSingle,
        builder: (context, currentValue, onChanged) {
          return _buildCategoryFilter(
            currentValue as String?,
            (value) => onChanged(value),
          );
        },
        getBadge: (value) {
          if (value == null || value == '全部分类') return null;
          return value as String;
        },
      ),
      // 尺寸过滤器
      FilterItem(
        id: 'sizes',
        title: '尺寸',
        type: FilterType.tagsMultiple,
        builder: (context, currentValue, onChanged) {
          return _buildSizeFilter(
            currentValue as List<String>?,
            (value) => onChanged(value),
          );
        },
        getBadge: (value) {
          if (value == null) return null;
          final list = value as List;
          if (list.isEmpty) return null;
          return '${list.length}';
        },
      ),
    ];
  }

  /// 构建分类过滤器内容
  Widget _buildCategoryFilter(
    String? selectedCategory,
    ValueChanged<String?> onChanged,
  ) {
    final allCategories = ['全部分类', ..._categories];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allCategories.map((category) {
        final isSelected =
            (selectedCategory ?? '全部分类') == category ||
            (category == '全部分类' && selectedCategory == null);

        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) {
            onChanged(category == '全部分类' ? null : category);
          },
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  /// 构建尺寸过滤器内容
  Widget _buildSizeFilter(
    List<String>? selectedSizes,
    ValueChanged<List<String>> onChanged,
  ) {
    final sizes = [
      {'label': '1×1', 'size': HomeWidgetSize.small},
      {'label': '2×1', 'size': HomeWidgetSize.medium},
      {'label': '2×2', 'size': HomeWidgetSize.large},
    ];

    final selected = selectedSizes ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((item) {
        final label = item['label'] as String;
        final isSelected = selected.contains(label);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (value) {
            final newSelected = List<String>.from(selected);
            if (value) {
              newSelected.add(label);
            } else {
              newSelected.remove(label);
            }
            onChanged(newSelected);
          },
          showCheckmark: true,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
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

  /// 构建组件网格视图
  Widget _buildWidgetGrid(List<HomeWidget> widgets) {
    if (widgets.isEmpty) {
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
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterValues.clear();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: Text('screens_clearFilterConditions'.tr),
            ),
          ],
        ),
      );
    }

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
                      Icon(widget.icon, size: 48, color: widget.color),
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
                    child:
                        widget.description != null
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
              child: widget.supportedSizes.length > 2
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.supportedSizes.length}个可用大小',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.supportedSizes
                          .map(
                            (size) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = screenSize.height * 0.8;
    // 在小屏幕下使用全宽，否则限制为600
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.95 : 600.0;

    final filteredWidgets = _getFilteredWidgets();

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: SuperCupertinoNavigationWrapper(
          // 基本配置
          title: Text('screens_addWidget'.tr),
          largeTitle: 'screens_addWidget'.tr,
          enableLargeTitle: true,

          // 主体内容 - 使用相同的过滤后的组件列表
          body: _buildWidgetGrid(filteredWidgets),

          // 搜索配置
          enableSearchBar: true,
          searchPlaceholder: '搜索组件名称、描述...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          // 搜索结果页面 - 使用相同的过滤逻辑
          searchBody: _buildWidgetGrid(filteredWidgets),

          // 多条件过滤配置
          enableMultiFilter: true,
          multiFilterItems: _buildFilterItems(),
          multiFilterBarHeight: 50,
          multiFilterToggleable: true,
          onMultiFilterChanged: (filters) {
            // 保存过滤值并刷新UI
            setState(() {
              _filterValues = filters;
            });
          },

          // 操作按钮
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '关闭',
            ),
          ],

          // 禁用自动返回按钮
          automaticallyImplyLeading: false,
        ),
      ),
    );
  }
}
