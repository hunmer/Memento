import 'package:flutter/material.dart';

/// 开关选择组件
///
/// 功能特性：
/// - 统一的样式和主题适配
/// - 支持标签、子标题和图标
/// - 可配置启用状态
class SwitchField extends StatelessWidget {
  /// 当前开关状态
  final bool value;

  /// 值变化的回调
  final ValueChanged<bool>? onChanged;

  /// 标签文本
  final String title;

  /// 子标题文本
  final String? subtitle;

  /// 左侧图标
  final IconData? icon;

  /// 是否启用
  final bool enabled;

  /// 主题色
  final Color primaryColor;

  const SwitchField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
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
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              )
            : null,
        secondary: icon != null
            ? Icon(
                icon,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              )
            : null,
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
