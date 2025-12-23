import 'package:flutter/material.dart';

/// 下拉选择组件（支持表单验证）
///
/// 功能特性：
/// - 支持 FormField 验证
/// - 统一的样式和主题适配
/// - 可配置的装饰器属性
/// - 支持 inline 模式（label在左，输入在右）
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

  /// 是否使用inline模式（label在左，输入在右）
  final bool inline;

  /// inline模式下label的宽度
  final double labelWidth;

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
    this.inline = false,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // inline 模式：label 在左，下拉框在右
    if (inline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                labelText ?? '',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<T>(
                value: value,
                items: items.map((item) {
                  // 确保菜单项文本右对齐
                  return DropdownMenuItem<T>(
                    value: item.value,
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      child: item.child,
                    ),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
                validator: validator,
                style: TextStyle(
                  fontSize: 17,
                  color: theme.colorScheme.onSurface,
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(right: 8),
                ),
                alignment: Alignment.centerRight,
                isExpanded: true,
              ),
            ),
          ],
        ),
      );
    }

    // 默认模式：独立卡片样式
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      dropdownColor: theme.colorScheme.surfaceContainerLow,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperStyle: helperStyle,
        prefixIcon: icon != null ? Icon(icon) : null,
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
