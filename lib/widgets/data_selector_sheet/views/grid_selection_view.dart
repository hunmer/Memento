import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_definition.dart';

/// 网格选择视图
///
/// 用于在选择器中展示网格形式的选项（如 AI 助手卡片）
class GridSelectionView extends StatelessWidget {
  /// 可选项列表
  final List<SelectableItem> items;

  /// 项目选中回调
  final ValueChanged<SelectableItem> onItemSelected;

  /// 选择模式
  final SelectionMode selectionMode;

  /// 已选中的项目 ID 集合（多选模式用）
  final Set<String>? selectedIds;

  /// 主题颜色
  final Color? themeColor;

  /// 空状态组件
  final Widget? emptyWidget;

  /// 空状态文本
  final String? emptyText;

  /// 网格列数
  final int crossAxisCount;

  /// 子项宽高比
  final double childAspectRatio;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 交叉轴间距
  final double crossAxisSpacing;

  const GridSelectionView({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.selectionMode = SelectionMode.single,
    this.selectedIds,
    this.themeColor,
    this.emptyWidget,
    this.emptyText,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_off_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyText ?? '暂无数据',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds?.contains(item.id) ?? false;

        return _GridItem(
          item: item,
          isSelected: isSelected,
          selectionMode: selectionMode,
          themeColor: themeColor,
          onTap: item.selectable ? () => onItemSelected(item) : null,
        );
      },
    );
  }
}

/// 网格项组件
class _GridItem extends StatelessWidget {
  final SelectableItem item;
  final bool isSelected;
  final SelectionMode selectionMode;
  final Color? themeColor;
  final VoidCallback? onTap;

  const _GridItem({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    this.themeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = item.color ?? themeColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? effectiveColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // 内容
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 图标或头像
                    _buildIcon(theme, effectiveColor),
                    const SizedBox(height: 8),
                    // 标题
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    // 副标题
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 多选模式的选中标记
              if (selectionMode == SelectionMode.multiple)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? effectiveColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? effectiveColor
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              // 禁用遮罩
              if (!item.selectable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_outline),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, Color effectiveColor) {
    const double iconSize = 40;

    // 优先使用头像
    if (item.avatarPath != null) {
      return CircleAvatar(
        backgroundImage: AssetImage(item.avatarPath!),
        radius: iconSize / 2,
      );
    }

    // 其次使用图标
    if (item.icon != null) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          item.icon,
          color: effectiveColor,
          size: iconSize * 0.5,
        ),
      );
    }

    // 默认使用首字母
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
          style: TextStyle(
            color: effectiveColor,
            fontSize: iconSize * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
