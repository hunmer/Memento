import 'package:flutter/material.dart';

/// 日期选择组件
///
/// 功能特性：
/// - 点击弹出日期选择器
/// - 显示格式化的日期
/// - 统一的样式和主题适配
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

  const DatePickerField({
    super.key,
    required this.date,
    required this.onTap,
    required this.formattedDate,
    required this.placeholder,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isDark ? Colors.grey[500] : Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate.isEmpty ? placeholder : formattedDate,
                style: TextStyle(
                  color: formattedDate.isEmpty
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : (isDark ? Colors.white : Colors.grey[900]),
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
