/// 目标追踪插件主页小组件工具函数
library;

/// 格式化日期
String formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

/// 获取当月天数
int daysInMonth(DateTime date) {
  final nextMonth = DateTime(date.year, date.month + 1, 1);
  final lastDayOfCurrentMonth = nextMonth.subtract(const Duration(days: 1));
  return lastDayOfCurrentMonth.day;
}
