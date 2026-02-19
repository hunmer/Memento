/// 打卡插件主页小组件工具函数
library;

import '../models/checkin_item.dart';

/// 获取当月签到天数
int getMonthlyCheckinCount(CheckinItem? item) {
  if (item == null) return 0;

  final today = DateTime.now();
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  int count = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    if (item.checkInRecords.containsKey(dateStr) &&
        item.checkInRecords[dateStr]!.isNotEmpty) {
      count++;
    }
  }

  return count;
}

/// 生成月度点数据
List<Map<String, dynamic>> generateMonthlyDotsData(
  CheckinItem? item,
) {
  final today = DateTime.now();
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  final result = <Map<String, dynamic>>[];

  for (int day = 1; day <= daysInMonth; day++) {
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final hasRecord =
        item?.checkInRecords.containsKey(dateStr) == true &&
        (item?.checkInRecords[dateStr]?.isEmpty == false);

    result.add({
      'day': day,
      'isChecked': hasRecord,
      'isToday': day == today.day,
    });
  }

  return result;
}

/// 获取最佳连续天数
int getBestStreak(CheckinItem? item) {
  if (item == null || item.checkInRecords.isEmpty) return 0;

  final sortedDates = item.checkInRecords.keys.toList()..sort();
  int bestStreak = 0;
  int currentStreak = 0;
  DateTime? lastDate;

  for (final dateStr in sortedDates) {
    final parts = dateStr.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    if (lastDate == null) {
      currentStreak = 1;
    } else {
      final difference = date.difference(lastDate).inDays;
      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        bestStreak = bestStreak > currentStreak ? bestStreak : currentStreak;
        currentStreak = 1;
      }
      // difference == 0 表示同一天多次记录，不增加连续天数
    }

    lastDate = date;
  }

  return bestStreak > currentStreak ? bestStreak : currentStreak;
}

/// 生成里程碑数据
List<Map<String, dynamic>> generateMilestones(int currentStreak) {
  final milestones = [7, 21, 30, 60, 100, 365];
  final result = <Map<String, dynamic>>[];

  for (final milestone in milestones) {
    result.add({
      'days': milestone,
      'label': milestone >= 365 ? '一年' : '$milestone天',
      'isReached': currentStreak >= milestone,
      'isCurrent':
          currentStreak < milestone &&
          (result.isEmpty || currentStreak > (result.last['days'] as int)),
    });
  }

  return result;
}

/// 生成从周一开始的周进度数据（用于 sleepTrackingCard）
List<Map<String, dynamic>> generateWeekProgressFromMonday(
  CheckinItem? item,
) {
  final today = DateTime.now();
  final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
  final result = <Map<String, dynamic>>[];

  // 找到本周一的日期（DateTime.weekday: 1=周一, 7=周日）
  final monday = today.subtract(Duration(days: today.weekday - 1));

  // 从周一开始生成7天的数据
  for (int i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isChecked =
        item?.checkInRecords.containsKey(dateStr) == true &&
        (item?.checkInRecords[dateStr]?.isEmpty == false);

    result.add({
      'day': weekDays[i],
      'achieved': isChecked,
      'progress': isChecked ? 1.0 : 0.0,
    });
  }

  return result;
}

/// 从选择器数据数组中提取小组件需要的数据 - 单个项目
Map<String, dynamic> extractCheckinItemData(List<dynamic> dataArray) {
  // 处理 CheckinItem 对象或 Map
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    // CheckinItem 等对象通过 toJson() 转换
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['name'] = itemData['name'] as String?;
  result['group'] = itemData['group'] as String?;
  result['icon'] = itemData['icon'] as int?;
  result['color'] = itemData['color'] as int?;
  return result;
}

/// 从选择器数据数组中提取多个签到项目的数据
Map<String, dynamic> extractCheckinsData(List<dynamic> dataArray) {
  // 将多个项目数据转换为列表格式
  final items = <Map<String, dynamic>>[];

  for (final rawData in dataArray) {
    Map<String, dynamic> itemData = {};

    if (rawData is Map<String, dynamic>) {
      itemData = rawData;
    } else if (rawData is dynamic && rawData.toJson != null) {
      // CheckinItem 等对象通过 toJson() 转换
      final jsonResult = rawData.toJson();
      if (jsonResult is Map<String, dynamic>) {
        itemData = jsonResult;
      }
    }

    items.add({
      'id': itemData['id'] as String?,
      'name': itemData['name'] as String?,
      'group': itemData['group'] as String?,
      'icon': itemData['icon'] as int?,
      'color': itemData['color'] as int?,
    });
  }

  return {'items': items};
}

/// 获取星期名称
String getWeekdayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

/// 获取月份名称
String getMonthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return names[month - 1];
}
