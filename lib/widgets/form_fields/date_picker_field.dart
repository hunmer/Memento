import 'package:flutter/material.dart';

/// 日期选择组件
///
/// 功能特性：
/// - 点击弹出日期选择器
/// - 显示格式化的日期
/// - 统一的样式和主题适配
/// - 支持 inline 模式（label在左，日期在右）
class DatePickerField extends StatelessWidget {
  /// 日期值（null表示未选择）
  final DateTime? date;

  /// 日期选择器的回调
  final VoidCallback onTap;

  /// 日期格式化字符串
  final String formattedDate;

  /// 占位符文本
  final String placeholder;

  /// 左侧图标
  final IconData icon;

  /// 标签文本（inline模式使用）
  final String? labelText;

  /// 是否使用inline模式（label在左，日期在右）
  final bool inline;

  /// inline模式下label的宽度
  final double labelWidth;

  const DatePickerField({
    super.key,
    required this.date,
    required this.onTap,
    required this.formattedDate,
    required this.placeholder,
    this.icon = Icons.calendar_today_outlined,
    this.labelText,
    this.inline = false,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // inline 模式：label 在左，日期在右
    if (inline) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Text(
                  formattedDate.isEmpty ? placeholder : formattedDate,
                  style: TextStyle(
                    fontSize: 17,
                    color:
                        formattedDate.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 默认模式：独立卡片样式
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate.isEmpty ? placeholder : formattedDate,
                style: TextStyle(
                  color: formattedDate.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
