bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime firstDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime lastDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

int daysInMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0).day;
}

List<DateTime> daysInRange(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var current = start;
  while (current.isBefore(end) || isSameDay(current, end)) {
    days.add(current);
    current = current.add(const Duration(days: 1));
  }
  return days;
}

String formatMonthYear(DateTime date) {
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String formatDayMonth(DateTime date) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]}';
}