import 'package:flutter/material.dart';

/// 多行文本输入组件
///
/// 功能特性：
/// - 带标签的多行输入框
/// - 统一的样式和主题适配
/// - 可自定义最小和最大行数
/// - 支持表单验证
/// - 支持 inline 模式（label在上方，适用于 FormFieldGroup）
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

  /// 是否使用inline模式（无边框，适用于 FormFieldGroup）
  final bool inline;

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
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // inline 模式：label 在上方，无边框
    if (inline) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null) ...[
              Text(
                labelText!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              minLines: minLines,
              enabled: enabled,
              validator: validator,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    // 默认模式：独立卡片样式
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
