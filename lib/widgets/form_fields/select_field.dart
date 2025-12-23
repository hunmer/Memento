import 'package:flutter/material.dart';

/// 下拉选择组件（支持表单验证）
///
/// 功能特性：
/// - 支持 FormField 验证
/// - 统一的样式和主题适配
/// - 可配置的装饰器属性
class SelectField<T> extends StatelessWidget {
  /// 当前选中的值
  final T? value;

  /// 值变化的回调
  final ValueChanged<T?>? onChanged;

  /// 下拉选项
  final List<DropdownMenuItem<T>> items;

  /// 标签文本
  final String? labelText;

  /// 提示文本
  final String? hintText;

  /// 验证器
  final String? Function(T?)? validator;

  /// 是否启用
  final bool enabled;

  /// 辅助文本
  final String? helperText;

  /// 辅助文本样式
  final TextStyle? helperStyle;

  /// 主题色
  final Color primaryColor;

  /// 左侧图标
  final IconData? icon;

  const SelectField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.helperText,
    this.helperStyle,
    this.primaryColor = const Color(0xFF607AFB),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        prefixIcon: icon != null ? Icon(icon) : null,
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
