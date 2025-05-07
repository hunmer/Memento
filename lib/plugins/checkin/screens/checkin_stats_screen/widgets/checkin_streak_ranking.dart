import 'package:flutter/material.dart';
import '../../../models/checkin_item.dart';

class CheckinStreakRanking extends StatelessWidget {
  final List<CheckinItem> checkinItems;

  const CheckinStreakRanking({
    super.key,
    required this.checkinItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankedItems = _calculateStreaks();

    if (rankedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '暂无打卡记录',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: rankedItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final rank = index + 1;
        final streakDays = item.streak;

        return ListTile(
          leading: _buildRankBadge(rank, theme),
          title: Text(item.name),
          subtitle: Text(item.group),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                '$streakDays天',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankBadge(int rank, ThemeData theme) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = Colors.amber;
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade300;
    } else if (rank == 3) {
      badgeColor = Colors.brown.shade300;
    } else {
      badgeColor = theme.colorScheme.surfaceContainerHighest;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: badgeColor,
      child: Text(
        '$rank',
        style: TextStyle(
          color: rank <= 3 ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  List<_RankedItem> _calculateStreaks() {
    List<_RankedItem> result = [];

    for (var item in checkinItems) {
      final streakDays = _calculateConsecutiveStreak(item);
      if (streakDays > 0) {
        result.add(_RankedItem(
          name: item.name,
          group: item.group,
          streak: streakDays,
        ));
      }
    }

    // 按连续打卡天数排序
    result.sort((a, b) => b.streak.compareTo(a.streak));
    
    // 只返回前10名
    return result.take(10).toList();
  }

  int _calculateConsecutiveStreak(CheckinItem item) {
    if (item.checkInRecords.keys.isEmpty) {
      return 0;
    }

    // 按日期排序
    final sortedDates = item.checkInRecords.keys.toList();
    sortedDates.sort((a, b) => b.compareTo(a)); // 降序排列，最新的日期在前

    int streak = 1; // 至少有一天的记录
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);

    // 检查最新记录是否是今天或昨天
    final latestDate = _parseDate(sortedDates.first);
    
    // 如果最新记录不是今天或昨天，则不计算连续打卡
    final dayDifference = todayWithoutTime.difference(latestDate).inDays;
    if (dayDifference > 1) {
      return 0;
    }

    // 计算连续打卡天数
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final current = _parseDate(sortedDates[i]);
      final next = _parseDate(sortedDates[i + 1]);

      final difference = current.difference(next).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break; // 连续打卡中断
      }
    }

    return streak;
  }
  // 解析日期字符串为DateTime对象
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format: $dateStr');
    }
    return DateTime(
      int.parse(parts[0]), // 年
      int.parse(parts[1]), // 月
      int.parse(parts[2]), // 日
    );
  }
}

class _RankedItem {
  final String name;
  final String group;
  final int streak;

  _RankedItem({
    required this.name,
    required this.group,
    required this.streak,
  });
}