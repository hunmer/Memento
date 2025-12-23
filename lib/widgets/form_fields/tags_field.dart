import 'package:flutter/material.dart';

/// 标签选择组件
///
/// 功能特性：
/// - 显示已选标签的Chips
/// - 点击添加按钮弹出对话框
/// - 支持删除标签
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

  const TagsField({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.addButtonText,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...tags.map((tag) => _buildTagChip(tag, isDark)),
          InkWell(
            onTap: onAddTag,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    addButtonText,
                    style: TextStyle(
                      color: primaryColor,
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
    );
  }

  Widget _buildTagChip(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withOpacity(0.2)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1E40AF),
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
              color: isDark
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }
}
