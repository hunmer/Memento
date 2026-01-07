import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final VoidCallback? onDeleteTap;

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
    this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = selectedTags.contains(tag.name);

        return _TagCard(
          key: ValueKey(tag.name),
          tag: tag,
          isSelected: isSelected,
          isBatchEditMode: isBatchEditMode,
          config: config,
          selectionMode: selectionMode,
          onTap: () => onSelectTag(tag.name),
          onLongPress: onLongPress != null ? () => onLongPress!(tag) : null,
          onDelete: isSelected && isBatchEditMode ? onDeleteTap : null,
        );
      },
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

/// 标签卡片组件
class _TagCard extends StatelessWidget {
  final TagItem tag;
  final bool isSelected;
  final bool isBatchEditMode;
  final TagsDialogConfig config;
  final TagsSelectionMode selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const _TagCard({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.isBatchEditMode,
    required this.config,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        height: config.tagCardHeight,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(config.tagCardRadius),
          border: Border.all(
            color: _getBorderColor(context),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 选择图标或标签图标
              _buildLeading(context),

              SizedBox(width: 12),

              // 标签信息
              Expanded(
                child: _buildTagInfo(context),
              ),

              // 删除按钮（批量编辑模式）
              if (isBatchEditMode && isSelected)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),

              // 选择指示器
              if (selectionMode != TagsSelectionMode.none && isSelected)
                Icon(
                  selectionMode == TagsSelectionMode.single
                      ? Icons.radio_button_checked
                      : Icons.check_circle,
                  color: config.selectedTagColor ??
                      Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建前导图标
  Widget _buildLeading(BuildContext context) {
    if (selectionMode != TagsSelectionMode.none || isBatchEditMode) {
      return Icon(
        isSelected
            ? (selectionMode == TagsSelectionMode.single
                ? Icons.radio_button_checked
                : Icons.check_circle)
            : (selectionMode == TagsSelectionMode.single
                ? Icons.radio_button_unchecked
                : Icons.circle_outlined),
        color: isSelected
            ? (config.selectedTagColor ??
                Theme.of(context).colorScheme.primary)
            : Colors.grey,
        size: 24,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tag.icon == Icons.label
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        tag.icon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// 构建标签信息
  Widget _buildTagInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 标签名称和分组
        Row(
          children: [
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 8),
            _buildGroupChip(context),
          ],
        ),

        // 注释
        if (tag.comment != null && tag.comment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tag.comment!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // 时间信息
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 4),
              Text(
                _formatTime(tag.lastUsedAt ?? tag.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建分组标签
  Widget _buildGroupChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.group,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      return (config.selectedTagColor ??
              Theme.of(context).colorScheme.primary)
          .withOpacity(0.1);
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// 获取边框颜色
  Color _getBorderColor(BuildContext context) {
    if (isSelected) {
      return config.selectedTagColor ??
          Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).dividerColor;
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy/MM/dd').format(dateTime);
    }
  }
}
