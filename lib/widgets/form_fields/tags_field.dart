import 'package:flutter/material.dart';

/// 标签选择组件
///
/// 功能特性：
/// - 显示已选标签的Chips
/// - 点击添加按钮弹出对话框
/// - 支持删除标签
/// - 支持快捷选择标签
class TagsField extends StatelessWidget {
  /// 已选标签列表
  final List<String> tags;

  /// 添加标签的回调
  final VoidCallback onAddTag;

  /// 删除标签的回调
  final Function(String tag) onRemoveTag;

  /// 添加按钮的文本
  final String addButtonText;

  /// 主题色
  final Color primaryColor;

  /// 快捷选择标签列表（点击可快速添加到已选标签）
  final List<String>? quickSelectTags;

  /// 快捷选择标签的回调
  final Function(String tag)? onQuickSelectTag;

  const TagsField({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.addButtonText,
    this.primaryColor = const Color(0xFF607AFB),
    this.quickSelectTags,
    this.onQuickSelectTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已选标签区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...tags.map((tag) => _buildTagChip(tag, theme)),
              InkWell(
                onTap: onAddTag,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        addButtonText,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 快捷选择标签区域
        if (quickSelectTags != null && quickSelectTags!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '最近使用',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickSelectTags!
                .where((tag) => !tags.contains(tag)) // 过滤已选标签
                .map((tag) => _buildQuickSelectChip(tag, theme))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// 构建已选标签的 Chip
  Widget _buildTagChip(String tag, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onRemoveTag(tag),
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快捷选择标签的 Chip
  Widget _buildQuickSelectChip(String tag, ThemeData theme) {
    return InkWell(
      onTap: () => onQuickSelectTag?.call(tag),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
