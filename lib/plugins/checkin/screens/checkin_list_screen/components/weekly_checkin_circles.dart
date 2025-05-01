import 'package:flutter/material.dart';
import '../../../models/checkin_item.dart';

class WeeklyCheckinCircles extends StatelessWidget {
  final CheckinItem item;

  const WeeklyCheckinCircles({
    super.key,
    required this.item,
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
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final hasCheckin = item.checkInRecords.keys.any((checkinDate) =>
            checkinDate.year == date.year &&
            checkinDate.month == date.month &&
            checkinDate.day == date.day);
        final isEnabled = item.frequency[index];

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor,
                  ),
                ),
                if (_isReminderDay(index + 1))
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
                Container(
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
                if (isToday && item.getTodayRecords().length > 1)
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
                        '${item.getTodayRecords().length}',
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