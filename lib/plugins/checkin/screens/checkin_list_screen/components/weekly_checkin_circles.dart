import 'package:flutter/material.dart';
import '../../../models/checkin_item.dart';

class WeeklyCheckinCircles extends StatelessWidget {
  final CheckinItem item;
  final Function(DateTime selectedDate)? onDateSelected;

  const WeeklyCheckinCircles({
    super.key,
    required this.item,
    this.onDateSelected,
  });

  bool _isReminderDay(int weekday) {
    if (item.reminderSettings?.type != ReminderType.weekly) {
      return false;
    }
    // 转换weekday为与item.reminderSettings.weekdays匹配的格式
    // Flutter中周一是1，周日是7，而我们存储的周日是0，周六是6
    int adjustedWeekday = weekday == 7 ? 0 : weekday;
    return item.reminderSettings!.weekdays.contains(adjustedWeekday);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final startDate = now.subtract(const Duration(days: 3));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = startDate.add(Duration(days: index));
        final weekdayIndex = date.weekday - 1;
        final weekdayStr = weekdays[weekdayIndex];
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hasCheckin = item.checkInRecords.containsKey(dateStr) && item.checkInRecords[dateStr]!.isNotEmpty;
        final checkinsCount = item.checkInRecords[dateStr]?.length ?? 0;
        final isEnabled = item.frequency[index];

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                  Text(
                  weekdayStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor,
                  ),
                ),
                if (_isReminderDay(date.weekday))
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (isEnabled && onDateSelected != null) {
                      onDateSelected?.call(DateTime(
                        date.year,
                        date.month,
                        date.day,
                      ));
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasCheckin
                        ? Colors.green
                        : isEnabled
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).primaryColor
                          : hasCheckin
                              ? Colors.green
                              : isEnabled
                                  ? Colors.grey
                                  : Colors.transparent,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: hasCheckin
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                  ),
                ),
                if (checkinsCount > 1)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$checkinsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}