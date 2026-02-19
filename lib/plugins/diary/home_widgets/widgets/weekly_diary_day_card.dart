/// 七日周报小组件 - 单日卡片
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data.dart';
import '../../models/diary_entry.dart';
import '../utils.dart';

/// 构建周报中的单日卡片组件
///
/// 显示日期、星期、心情和日记标题
Widget buildDayCard(
  BuildContext context,
  DateTime date,
  WeekDiaryCardData cardData,
) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color:
            cardData.isToday
                ? Colors.indigo.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border:
            cardData.isToday ? Border.all(color: Colors.indigo, width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () => openDiaryEditor(context, date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 星期几
              Text(
                cardData.weekday,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cardData.isToday ? Colors.indigo : Colors.grey,
                  fontWeight:
                      cardData.isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              // 日期数字
              Text(
                cardData.dayNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardData.isToday ? Colors.indigo : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // 心情
              if (cardData.mood != null)
                Text(cardData.mood!, style: const TextStyle(fontSize: 18))
              else
                const SizedBox(height: 18),
              // 标题（如果有）
              Text(
                cardData.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: cardData.hasEntry ? Colors.black87 : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 根据日记条目创建周报卡片数据
WeekDiaryCardData createWeekCardData(
  DateTime date,
  DiaryEntry? entry,
) {
  final now = DateTime.now();
  return WeekDiaryCardData(
    date: date,
    isToday: DateUtils.isSameDay(date, now),
    weekday: DateFormat('E').format(date),
    dayNumber: DateFormat('d').format(date),
    mood: entry?.mood,
    title: entry?.title,
    hasEntry: entry != null,
  );
}
