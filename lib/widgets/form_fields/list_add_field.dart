import 'package:flutter/material.dart';

/// 列表添加组件
///
/// 功能特性：
/// - 显示列表项（可勾选、删除）
/// - 底部有添加按钮和输入框
/// - 支持回车添加
/// - 支持泛型，可与任何数据模型配合使用
class ListAddField<T> extends StatelessWidget {
  /// 列表项数据
  final List<T> items;

  /// 输入控制器
  final TextEditingController controller;

  /// 添加项的回调
  final VoidCallback onAdd;

  /// 切换完成状态的回调
  final Function(int index) onToggle;

  /// 删除项的回调
  final Function(int index) onRemove;

  /// 获取标题的回调
  final String Function(T item) getTitle;

  /// 获取完成状态的回调
  final bool Function(T item) getIsCompleted;

  /// 添加按钮的文本
  final String addButtonText;

  /// 主题色
  final Color primaryColor;

  const ListAddField({
    super.key,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
    required this.getTitle,
    required this.getIsCompleted,
    required this.addButtonText,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // 列表项
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final title = getTitle(item);
              final isCompleted = getIsCompleted(item);

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200]!,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isCompleted,
                        onChanged: (_) => onToggle(index),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: primaryColor,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onRemove(index),
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ],
                ),
              );
            }),
          // 添加输入框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: primaryColor, size: 20),
                      const SizedBox(width: 8),
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
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
