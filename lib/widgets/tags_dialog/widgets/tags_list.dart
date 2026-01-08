import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = selectedTags.contains(tag.name);
          return _TagPill(
            key: ValueKey('tag_${tag.createdAt.millisecondsSinceEpoch}'),
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
        },
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标签内容（可点击）
              InkWell(
                onTap: inherited.isBatchEditMode ? null : inherited.onTap,
                onLongPress: inherited.isBatchEditMode ? null : inherited.onLongPress,
                borderRadius: BorderRadius.circular(16),
                child: _buildPillContent(context, inherited),
              ),

              // 编辑和删除按钮行（批量编辑模式时显示）
              if (inherited.isBatchEditMode)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inherited.onEdit != null)
                        InkWell(
                          onTap: inherited.onEdit,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit, color: Colors.blue, size: 14),
                          ),
                        ),
                      if (inherited.onEdit != null && inherited.onDelete != null)
                        SizedBox(width: 4),
                      if (inherited.onDelete != null)
                        InkWell(
                          onTap: inherited.onDelete,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.red, size: 14),
                          ),
                        ),
                    ],
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
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签图标 - 紧贴顶部，圆角融合
          if (tag.icon != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tag.color ?? Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tag.icon,
                    size: 22,
                    color: _getIconColor(context),
                  ),
                ),
              ),
            ),

          // 标签名称
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(
              tag.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getTextColor(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        ],
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      // 选中时使用图标的颜色，带透明度
      return (tag.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2);
    }
    // 未选中时透明背景
    return Colors.transparent;
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
    required this.tag,
    required this.isSelected,
    required this.isBatchEditMode,
    required this.config,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    required super.child,
  });

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
