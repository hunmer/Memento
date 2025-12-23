import 'package:flutter/material.dart';

/// 多行文本输入组件
///
/// 功能特性：
/// - 带标签的多行输入框
/// - 统一的样式和主题适配
/// - 可自定义最小和最大行数
/// - 支持表单验证
class TextAreaField extends StatelessWidget {
  /// 输入控制器
  final TextEditingController controller;

  /// 标签文本
  final String? labelText;

  /// 提示文本
  final String hintText;

  /// 最小行数
  final int minLines;

  /// 最大行数（null表示无限制）
  final int? maxLines;

  /// 主题色
  final Color primaryColor;

  /// 验证器
  final String? Function(String?)? validator;

  /// 是否启用
  final bool enabled;

  /// 辅助文本
  final String? helperText;

  /// 辅助文本样式
  final TextStyle? helperStyle;

  const TextAreaField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.minLines = 4,
    this.maxLines,
    this.primaryColor = const Color(0xFF607AFB),
    this.validator,
    this.enabled = true,
    this.helperText,
    this.helperStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
