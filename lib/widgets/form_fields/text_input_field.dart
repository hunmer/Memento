import 'package:flutter/material.dart';

/// 单行文本输入组件（支持表单验证）
///
/// 功能特性：
/// - 支持 FormField 验证
/// - 统一的样式和主题适配
/// - 可配置的装饰器属性
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

  /// 是否密码输入
  final bool obscureText;

  /// 主题色
  final Color primaryColor;

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
    this.obscureText = false,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      autofocus: autofocus,
      obscureText: obscureText,
      style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
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
