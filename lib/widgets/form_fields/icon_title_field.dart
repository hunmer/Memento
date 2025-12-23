import 'package:flutter/material.dart';

/// 带图标选择的标题输入组件
///
/// 功能特性：
/// - 左侧可点击的图标选择器
/// - 右侧标题输入框
/// - 统一的样式和主题适配
class IconTitleField extends StatelessWidget {
  /// 输入控制器
  final TextEditingController controller;

  /// 当前选择的图标
  final IconData? icon;

  /// 点击图标选择器的回调
  final VoidCallback onIconTap;

  /// 提示文本
  final String hintText;

  /// 文本样式
  final TextStyle? textStyle;

  const IconTitleField({
    super.key,
    required this.controller,
    required this.icon,
    required this.onIconTap,
    required this.hintText,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 图标选择器
        GestureDetector(
          onTap: onIconTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.assignment,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 标题输入框
        Expanded(
          child: TextField(
            controller: controller,
            style: textStyle ??
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
