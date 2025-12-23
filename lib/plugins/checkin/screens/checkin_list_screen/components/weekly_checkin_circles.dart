import 'package:flutter/material.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';

class WeeklyCheckinCircles extends StatelessWidget {
  final CheckinItem item;
  final Function(DateTime selectedDate)? onDateSelected;

  const WeeklyCheckinCircles({
    super.key,
    required this.item,
    this.onDateSelected,
  });

  DateTime _getStartOfWeek(DateTime date) {
    // 获取当前日期的周一
    final int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final weekdayStr = weekdays[index];
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hasCheckin = item.checkInRecords.containsKey(dateStr) &&
            item.checkInRecords[dateStr]!.isNotEmpty;
        final checkinsCount = item.checkInRecords[dateStr]?.length ?? 0;

        // 检查日期是否在未来
        final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

        return Expanded(
          child: GestureDetector(
          onTap: () {
            // 如果是未来日期，不允许点击
            if (isFuture) return;
            
            if (onDateSelected != null) {
              onDateSelected?.call(DateTime(
                date.year,
                date.month,
                date.day,
              ));
            }
          },
          child: Column(
            children: [
              // 星期几
              Text(
                weekdayStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 4),
              // 日期圆角矩形
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasCheckin
                      ? item.color.withValues(alpha: 0.2) // 打卡显示淡色背景
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), // 未打卡显示浅灰
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !hasCheckin
                      ? Border.all(
                          color: item.color,
                          width: 1,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday || hasCheckin ? FontWeight.bold : FontWeight.normal,
                        color: hasCheckin
                            ? item.color // 打卡显示主题色文字
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    // 如果次数大于1，显示小红点或数字
                    if (checkinsCount > 1)
                       Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              '$checkinsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      }),
    );
  }
}