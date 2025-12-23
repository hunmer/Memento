import 'package:flutter/material.dart';

/// 单行文本输入组件（支持表单验证）
///
/// 功能特性：
/// - 支持 FormField 验证
/// - 统一的样式和主题适配
/// - 可配置的装饰器属性
/// - 支持 inline 模式（label在左，输入在右）
class TextInputField extends StatelessWidget {
  /// 输入控制器
  final TextEditingController controller;

  /// 标签文本
  final String labelText;

  /// 提示文本
  final String? hintText;

  /// 验证器
  final String? Function(String?)? validator;

  /// 是否启用
  final bool enabled;

  /// 最大行数
  final int? maxLines;

  /// 最小行数
  final int? minLines;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 是否自动聚焦
  final bool autofocus;

  /// 辅助文本
  final String? helperText;

  /// 辅助文本样式
  final TextStyle? helperStyle;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 后缀组件（inline模式下显示在输入框右侧，与输入框并列）
  final Widget? suffix;

  /// 是否密码输入
  final bool obscureText;

  /// 主题色
  final Color primaryColor;

  /// 是否使用inline模式（label在左，输入在右）
  final bool inline;

  /// inline模式下label的宽度
  final double labelWidth;

  const TextInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.autofocus = false,
    this.helperText,
    this.helperStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.primaryColor = const Color(0xFF607AFB),
    this.inline = false,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // inline 模式：label 在左，输入框在右
    if (inline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      validator: validator,
                      enabled: enabled,
                      maxLines: maxLines,
                      minLines: minLines,
                      keyboardType: keyboardType,
                      autofocus: autofocus,
                      obscureText: obscureText,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 17,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                        contentPadding: suffix != null || suffixIcon != null
                            ? const EdgeInsets.only(right: 8)
                            : EdgeInsets.zero,
                        suffixIcon: suffixIcon,
                      ),
                    ),
                  ),
                  if (suffix != null) suffix!,
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 默认模式：独立卡片样式
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      autofocus: autofocus,
      obscureText: obscureText,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
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
