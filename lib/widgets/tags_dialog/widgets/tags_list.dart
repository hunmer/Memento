import 'package:flutter/material.dart';
import '../models/models.dart';

/// 标签列表组件
class TagsList extends StatelessWidget {
  /// 标签列表
  final List<TagItem> tags;

  /// 已选择的标签
  final List<String> selectedTags;

  /// 是否批量编辑模式
  final bool isBatchEditMode;

  /// 配置
  final TagsDialogConfig config;

  /// 选择模式
  final TagsSelectionMode selectionMode;

  /// 选择标签回调
  final Function(String tagName) onSelectTag;

  /// 长按回调
  final Function(TagItem tag)? onLongPress;

  /// 删除点击回调
  final Function(TagItem tag)? onDeleteTap;

  /// 编辑点击回调
  final Function(TagItem tag)? onEditTap;

  /// 添加标签回调
  final Function(String group)? onAddTag;

  const TagsList({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.isBatchEditMode,
    required this.config,
    required this.selectionMode,
    required this.onSelectTag,
    this.onLongPress,
    this.onDeleteTap,
    this.onEditTap,
    this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return _buildEmptyState();
    }

    return PrimaryScrollController.none(
      child: CustomScrollView(
        primary: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(tags.length, (index) {
                  final tag = tags[index];
                  final isSelected = selectedTags.contains(tag.name);
                  return _TagPill(
                    key: ValueKey('${tag.name}_$index'),
                    tag: tag,
                    isSelected: isSelected,
                    isBatchEditMode: isBatchEditMode,
                    config: config,
                    selectionMode: selectionMode,
                    onTap: () => onSelectTag(tag.name),
                    onLongPress: onLongPress != null ? () => onLongPress!(tag) : null,
                    onDelete: onDeleteTap != null ? () => onDeleteTap!(tag) : null,
                    onEdit: onEditTap != null ? () => onEditTap!(tag) : null,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            config.emptyStateText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签胶囊按钮组件
class _TagPill extends StatelessWidget {
  final TagItem tag;
  final bool isSelected;
  final bool isBatchEditMode;
  final TagsDialogConfig config;
  final TagsSelectionMode selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TagPill({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.isBatchEditMode,
    required this.config,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // 使用稳定的 key，避免因状态变化导致 widget 重建问题
    return _TagPillInherited(
      tag: tag,
      isSelected: isSelected,
      isBatchEditMode: isBatchEditMode,
      config: config,
      selectionMode: selectionMode,
      onTap: onTap,
      onLongPress: onLongPress,
      onDelete: onDelete,
      onEdit: onEdit,
      child: Builder(
        builder: (context) {
          final inherited = _TagPillInherited.of(context);

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标签内容（可点击）
              InkWell(
                onTap: inherited.isBatchEditMode ? null : inherited.onTap,
                onLongPress: inherited.isBatchEditMode ? null : inherited.onLongPress,
                borderRadius: BorderRadius.circular(20),
                child: _buildPillContent(context, inherited),
              ),

              // 编辑按钮（始终存在，用 opacity 控制可见性）
              Opacity(
                opacity: inherited.isBatchEditMode && inherited.onEdit != null ? 1.0 : 0.0,
                child: InkWell(
                  onTap: inherited.onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: EdgeInsets.only(left: 4),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: Colors.blue, size: 16),
                  ),
                ),
              ),

              // 删除按钮（始终存在，用 opacity 控制可见性）
              Opacity(
                opacity: inherited.isBatchEditMode && inherited.onDelete != null ? 1.0 : 0.0,
                child: InkWell(
                  onTap: inherited.onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: EdgeInsets.only(left: 4),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillContent(BuildContext context, _TagPillInherited inherited) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(context),
          width: inherited.isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签图标
          if (tag.icon != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: tag.color ?? Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                tag.icon,
                size: 12,
                color: _getIconColor(context),
              ),
            ),

          if (tag.icon != null) SizedBox(width: 6),

          // 标签名称
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
          ),

          // 选择指示器（非批量编辑模式）
          if (!inherited.isBatchEditMode &&
              inherited.selectionMode != TagsSelectionMode.none &&
              inherited.isSelected)
            Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                inherited.selectionMode == TagsSelectionMode.single
                    ? Icons.radio_button_checked
                    : Icons.check_circle,
                size: 16,
                color: config.selectedTagColor ??
                    Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      return (config.selectedTagColor ??
              Theme.of(context).colorScheme.primary)
          .withOpacity(0.15);
    }
    return tag.color?.withOpacity(0.15) ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// 获取边框颜色
  Color _getBorderColor(BuildContext context) {
    if (isSelected) {
      return config.selectedTagColor ??
          Theme.of(context).colorScheme.primary;
    }
    return tag.color ?? Theme.of(context).colorScheme.outline;
  }

  /// 获取文本颜色
  Color _getTextColor(BuildContext context) {
    if (isSelected) {
      return config.selectedTagColor ??
          Theme.of(context).colorScheme.primary;
    }
    return tag.color ?? Theme.of(context).colorScheme.onSurface;
  }

  /// 获取图标颜色
  Color _getIconColor(BuildContext context) {
    if (tag.color != null) {
      final brightness = ThemeData.estimateBrightnessForColor(tag.color!);
      return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
    return Theme.of(context).colorScheme.primary;
  }
}

/// InheritedWidget 用于在 _TagPill 内部传递数据
class _TagPillInherited extends InheritedWidget {
  final TagItem tag;
  final bool isSelected;
  final bool isBatchEditMode;
  final TagsDialogConfig config;
  final TagsSelectionMode selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TagPillInherited({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.isBatchEditMode,
    required this.config,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    required Widget child,
  }) : super(child: child);

  static _TagPillInherited of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_TagPillInherited>();
    assert(result != null, 'No _TagPillInherited found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_TagPillInherited oldWidget) {
    return oldWidget.isSelected != isSelected ||
        oldWidget.isBatchEditMode != isBatchEditMode;
  }
}
