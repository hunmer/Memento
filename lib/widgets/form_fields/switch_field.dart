import 'package:flutter/material.dart';

/// 开关选择组件
///
/// 功能特性：
/// - 统一的样式和主题适配
/// - 支持标签、子标题和图标
/// - 可配置启用状态
/// - 支持 inline 模式（适用于 FormFieldGroup）
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

  /// 是否使用inline模式（无边框，适用于 FormFieldGroup）
  final bool inline;

  const SwitchField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
    this.primaryColor = const Color(0xFF607AFB),
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // inline 模式：无边框，适用于 FormFieldGroup
    if (inline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      );
    }

    // 默认模式：独立卡片样式
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              )
            : null,
        secondary: icon != null
            ? Icon(
                icon,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        activeColor: theme.colorScheme.primary,
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
