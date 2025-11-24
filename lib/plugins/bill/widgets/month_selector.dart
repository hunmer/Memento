import 'package:flutter/material.dart';

/// 月份选择器组件
/// 显示一个水平滚动的月份列表，每个月份卡片显示收入和支出统计
class MonthSelector extends StatelessWidget {
  /// 当前选中的月份
  final DateTime selectedMonth;

  /// 月份选择回调
  final ValueChanged<DateTime> onMonthSelected;

  /// 获取指定月份的统计数据
  final Map<String, double> Function(DateTime month) getMonthStats;

  /// 月份数量（默认6个月）
  final int monthCount;

  /// 主题色
  final Color primaryColor;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.getMonthStats,
    this.monthCount = 6,
    this.primaryColor = const Color(0xFF3498DB),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 生成最近N个月的列表
    final months = List.generate(monthCount, (index) {
      return DateTime(
        selectedMonth.year,
        selectedMonth.month - (monthCount - 1 - index),
      );
    });

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month.year == selectedMonth.year &&
                           month.month == selectedMonth.month;
          final stats = getMonthStats(month);

          return GestureDetector(
            onTap: () => onMonthSelected(month),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.grey[800] : Colors.white)
                    : (isDark ? Colors.transparent : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: primaryColor, width: 2)
                    : null,
                boxShadow: isSelected || !isDark
                    ? [BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 4,
                      )]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${month.month}月',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.grey[500] : Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${_formatCompact(stats['income'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2ECC71), // 收入颜色
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '-${_formatCompact(stats['expense'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE74C3C), // 支出颜色
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 格式化数字为紧凑形式
  String _formatCompact(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
