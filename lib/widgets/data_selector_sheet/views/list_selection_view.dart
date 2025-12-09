import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_definition.dart';

/// 列表选择视图
///
/// 用于在选择器中展示列表形式的选项
class ListSelectionView extends StatelessWidget {
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

  /// 是否显示分割线
  final bool showDivider;

  const ListSelectionView({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.selectionMode = SelectionMode.single,
    this.selectedIds,
    this.themeColor,
    this.emptyWidget,
    this.emptyText,
    this.showDivider = true,
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
                  Icons.inbox_outlined,
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          showDivider ? const Divider(height: 1, indent: 72) : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds?.contains(item.id) ?? false;

        return _ListItem(
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

/// 列表项组件
class _ListItem extends StatelessWidget {
  final SelectableItem item;
  final bool isSelected;
  final SelectionMode selectionMode;
  final Color? themeColor;
  final VoidCallback? onTap;

  const _ListItem({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    this.themeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = themeColor ?? theme.colorScheme.primary;

    return ListTile(
      leading: _buildLeading(theme, effectiveColor),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _buildTrailing(theme, effectiveColor),
      enabled: item.selectable,
      selected: isSelected,
      selectedTileColor: effectiveColor.withOpacity(0.08),
      onTap: onTap,
    );
  }

  Widget? _buildLeading(ThemeData theme, Color effectiveColor) {
    // 优先使用头像
    if (item.avatarPath != null) {
      return CircleAvatar(
        backgroundImage: AssetImage(item.avatarPath!),
        radius: 20,
      );
    }

    // 其次使用图标
    if (item.icon != null) {
      return CircleAvatar(
        backgroundColor: (item.color ?? effectiveColor).withOpacity(0.15),
        radius: 20,
        child: Icon(
          item.icon,
          color: item.color ?? effectiveColor,
          size: 20,
        ),
      );
    }

    // 使用颜色圆圈
    if (item.color != null) {
      return CircleAvatar(
        backgroundColor: item.color,
        radius: 20,
      );
    }

    // 默认使用首字母
    return CircleAvatar(
      backgroundColor: effectiveColor.withOpacity(0.15),
      radius: 20,
      child: Text(
        item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget? _buildTrailing(ThemeData theme, Color effectiveColor) {
    if (selectionMode == SelectionMode.multiple) {
      return Checkbox(
        value: isSelected,
        onChanged: item.selectable ? (_) => onTap?.call() : null,
        activeColor: effectiveColor,
      );
    }

    // 单选模式显示箭头
    if (item.selectable) {
      return Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outline,
      );
    }

    return null;
  }
}
