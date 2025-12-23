import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'filter_models.dart';

/// 多条件过滤栏组件
class MultiFilterBar extends StatefulWidget {
  /// 过滤条件列表
  final List<FilterItem> filterItems;

  /// 过滤状态
  final MultiFilterState filterState;

  /// 过滤条件变更回调
  final ValueChanged<Map<String, dynamic>>? onFilterChanged;

  /// 高度
  final double height;

  const MultiFilterBar({
    super.key,
    required this.filterItems,
    required this.filterState,
    this.onFilterChanged,
    this.height = 50,
  });

  @override
  State<MultiFilterBar> createState() => _MultiFilterBarState();
}

class _MultiFilterBarState extends State<MultiFilterBar> {
  /// 当前选中的过滤项索引（null表示在第一层）
  int? _selectedFilterIndex;

  /// 是否显示详情层
  bool get _isDetailView => _selectedFilterIndex != null;

  @override
  void initState() {
    super.initState();
    // 监听过滤状态变化
    widget.filterState.addListener(_onFilterStateChanged);

    // 初始化过滤值
    for (var item in widget.filterItems) {
      if (item.initialValue != null &&
          !widget.filterState.hasFilter(item.id)) {
        widget.filterState.setValue(item.id, item.initialValue);
      }
    }
  }

  @override
  void dispose() {
    widget.filterState.removeListener(_onFilterStateChanged);
    super.dispose();
  }

  /// 过滤状态变更回调
  void _onFilterStateChanged() {
    widget.onFilterChanged?.call(widget.filterState.getAllValues());
  }

  /// 清空所有过滤
  void _clearAllFilters() {
    widget.filterState.clearAll();
    setState(() {
      _selectedFilterIndex = null;
    });
  }

  /// 选择过滤项
  void _selectFilter(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
  }

  /// 返回第一层
  void _backToList() {
    setState(() {
      _selectedFilterIndex = null;
    });
  }

  /// 构建过滤项的badge文本
  String? _buildBadge(FilterItem item) {
    final value = widget.filterState.getValue(item.id);
    if (item.getBadge != null) {
      return item.getBadge!(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.12),
            width: 0.5,
          ),
        ),
      ),
      child: _isDetailView ? _buildDetailView() : _buildListView(),
    );
  }

  /// 构建第一层：过滤项列表
  Widget _buildListView() {
    return Row(
      children: [
        // 过滤项列表（可滚动）
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.filterItems.length,
            itemBuilder: (context, index) {
              final item = widget.filterItems[index];
              final badge = _buildBadge(item);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FilterChip(
                  label: item.title,
                  badge: badge,
                  onTap: () => _selectFilter(index),
                ),
              );
            },
          ),
        ),

        // 清空所有按钮
        if (widget.filterState.hasAnyFilter)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _clearAllFilters,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear_all,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'core_clearAll'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建第二层：过滤详情
  Widget _buildDetailView() {
    if (_selectedFilterIndex == null ||
        _selectedFilterIndex! >= widget.filterItems.length) {
      return const SizedBox.shrink();
    }

    final item = widget.filterItems[_selectedFilterIndex!];

    return Row(
      children: [
        // 返回按钮
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: _backToList,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),

        // 标题
        Text(
          item.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(width: 16),

        // 内容区域（可滚动）
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 12),
            child: item.builder(
              context,
              widget.filterState.getValue(item.id),
              (value) {
                widget.filterState.setValue(item.id, value);
                setState(() {}); // 更新UI
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 过滤条件芯片组件
class _FilterChip extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadge = badge != null && badge!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasBadge
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasBadge ? FontWeight.w600 : FontWeight.w500,
                color: hasBadge
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
