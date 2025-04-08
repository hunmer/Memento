String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateToCompare = DateTime(date.year, date.month, date.day);

  if (dateToCompare == today) {
    return '今天';
  } else if (dateToCompare == yesterday) {
    return '昨天';
  } else {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

String formatDateFull(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}