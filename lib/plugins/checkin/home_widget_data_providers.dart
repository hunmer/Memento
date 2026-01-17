part of 'home_widgets.dart';

/// 打卡插件主页小组件数据提供者
/// 提供单个签到项目和多个签到项目的公共小组件数据

/// 公共小组件提供者函数 - 单个签到项目
Future<Map<String, Map<String, dynamic>>> _provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // data 包含：id, name, group, icon, color
  final name = (data['name'] as String?) ?? '签到项目';
  final group = (data['group'] as String?) ?? '';
  final colorValue = (data['color'] as int?) ?? 0xFF007AFF;
  final iconCode = (data['icon'] as int?) ?? Icons.checklist.codePoint;

  // 获取插件实例以获取实时数据
  final plugin =
      PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
  CheckinItem? item;
  int consecutiveDays = 0;
  bool isCheckedToday = false;

  if (plugin != null) {
    final itemId = data['id'] as String?;
    if (itemId != null) {
      try {
        item = plugin.checkinItems.firstWhere(
          (i) => i.id == itemId,
          orElse: () => throw Exception('项目不存在'),
        );
        consecutiveDays = item.getConsecutiveDays();
        isCheckedToday = item.isCheckedToday();
      } catch (_) {
        // 项目不存在，使用默认值
      }
    }
  }

  // 计算本周签到天数
  int weeklyCheckins = 0;
  if (item != null) {
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (item.checkInRecords.containsKey(dateStr) &&
          item.checkInRecords[dateStr]!.isNotEmpty) {
        weeklyCheckins++;
      }
    }
  }

  return {
    // 活动进度卡片：显示连续签到天数
    'activityProgressCard': {
      'title': name,
      'subtitle': '连续签到',
      'value': consecutiveDays.toDouble(),
      'unit': '天',
      'activities': weeklyCheckins,
      'totalProgress': 7,
      'completedProgress': weeklyCheckins,
    },

    // 月度进度带点卡片：显示当月签到进度
    'monthlyProgressDotsCard': {
      'title': name,
      'subtitle': '${DateTime.now().month}月 • ${_getMonthlyCheckinCount(item)}d/${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day}d',
      'currentDay': _getMonthlyCheckinCount(item),
      'totalDays':
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day,
      'percentage':
          ((_getMonthlyCheckinCount(item) /
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month + 1,
                        0,
                      ).day) *
                  100)
              .toInt(),
    },

    // 睡眠追踪卡片（复用）：显示连续签到天数作为睡眠数据
    'sleepTrackingCard': {
      'title': name,
      'mainValue': consecutiveDays.toDouble(),
      'statusLabel': consecutiveDays >= 30 ? '习惯养成' : '持续打卡',
      'unit': '次',
      'icon': iconCode,
      'weeklyProgress': _generateWeekProgressFromMonday(item),
    },

    // 习惯连续追踪：显示连续签到和里程碑
    'habitStreakTrackerCard': {
      'title': name,
      'currentStreak': consecutiveDays,
      'bestStreak': _getBestStreak(item),
      'totalCheckins': item?.checkInRecords.length ?? 0,
      'milestones': _generateMilestones(consecutiveDays),
      'todayChecked': isCheckedToday,
      'weekProgress': weeklyCheckins,
    },

    // 月度点追踪卡片：显示当月签到状态点
    'monthlyDotTrackerCard': {
      'title': name,
      'subtitle': group.isNotEmpty ? group : '签到',
      'iconCodePoint': iconCode,
      'currentValue': _getMonthlyCheckinCount(item),
      'totalDays':
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day,
      'daysData': _generateMonthlyDotsData(item),
    },

    // 签到项目卡片：显示项目图标、名称、今日状态和热力图
    'checkinItemCard': {
      'id': data['id'],
      'title': name,
      'subtitle': group.isNotEmpty ? group : '签到',
      'iconCodePoint': iconCode,
      'color': colorValue,
      'isCheckedToday': isCheckedToday,
      // 周数据（用于 medium 尺寸）
      'weekData': List.generate(7, (index) {
        final i = 6 - index;
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hasRecord =
            item?.checkInRecords.containsKey(dateStr) == true &&
            (item?.checkInRecords[dateStr]?.isEmpty == false);
        return {
          'day': '周${['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1]}',
          'isChecked': hasRecord,
        };
      }),
      // 月度数据（用于 large 尺寸）
      'daysData': _generateMonthlyDotsData(item),
    },
  };
}

/// 为多个签到项目提供公共小组件数据
Future<Map<String, Map<String, dynamic>>> _provideCommonWidgetsForMultiple(
  Map<String, dynamic> data,
) async {
  // data 格式: {'items': [{'id': ..., 'name': ..., 'group': ..., 'icon': ..., 'color': ...}, ...]}
  final itemsList = data['items'] as List<dynamic>?;
  if (itemsList == null || itemsList.isEmpty) {
    return {};
  }

  // 获取插件实例以获取实时数据
  final plugin =
      PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;

  // 构建每个项目的数据
  final List<Map<String, dynamic>> checkinItemCards = [];

  int todayCheckedCount = 0;

  for (final itemData in itemsList) {
    if (itemData is! Map<String, dynamic>) continue;

    final itemId = itemData['id'] as String?;
    final name = (itemData['name'] as String?) ?? '签到项目';
    final group = (itemData['group'] as String?) ?? '';
    final colorValue = (itemData['color'] as int?) ?? 0xFF007AFF;
    final iconCode = (itemData['icon'] as int?) ?? Icons.checklist.codePoint;

    CheckinItem? item;
    bool isCheckedToday = false;

    if (plugin != null && itemId != null) {
      try {
        item = plugin.checkinItems.firstWhere(
          (i) => i.id == itemId,
          orElse: () => throw Exception('项目不存在'),
        );
        isCheckedToday = item.isCheckedToday();
      } catch (_) {
        // 项目不存在，使用默认值
      }
    }

    if (isCheckedToday) todayCheckedCount++;

    // 生成周数据
    final weekData = List.generate(7, (index) {
      final i = 6 - index;
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasRecord =
          item?.checkInRecords.containsKey(dateStr) == true &&
          (item?.checkInRecords[dateStr]?.isEmpty == false);
      return {
        'day': '周${['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1]}',
        'isChecked': hasRecord,
      };
    });

    checkinItemCards.add({
      'id': itemId,
      'title': name,
      'subtitle': group.isNotEmpty ? group : '签到',
      'iconCodePoint': iconCode,
      'color': colorValue,
      'isCheckedToday': isCheckedToday,
      'weekData': weekData,
    });
  }

  // 计算月度签到数据
  final today = DateTime.now();
  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
  int monthlyCheckinCount = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    for (final itemData in itemsList) {
      if (itemData is! Map<String, dynamic>) continue;
      final itemId = itemData['id'] as String?;
      if (plugin != null && itemId != null) {
        try {
          final item = plugin.checkinItems.firstWhere(
            (i) => i.id == itemId,
            orElse: () => throw Exception('项目不存在'),
          );
          if (item.checkInRecords.containsKey(dateStr) &&
              item.checkInRecords[dateStr]!.isNotEmpty) {
            monthlyCheckinCount++;
            break; // 只要有一个项目打卡就算
          }
        } catch (_) {}
      }
    }
  }

  (monthlyCheckinCount / daysInMonth * 100).clamp(0, 100);

  // 获取所有项目的本月签到记录
  final allMonthlyRecords = <String>[];
  for (int day = 1; day <= daysInMonth; day++) {
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    bool hasAnyCheckin = false;
    for (final itemData in itemsList) {
      if (itemData is! Map<String, dynamic>) continue;
      final itemId = itemData['id'] as String?;
      if (plugin != null && itemId != null) {
        try {
          final item = plugin.checkinItems.firstWhere(
            (i) => i.id == itemId,
            orElse: () => throw Exception('项目不存在'),
          );
          if (item.checkInRecords.containsKey(dateStr) &&
              item.checkInRecords[dateStr]!.isNotEmpty) {
            hasAnyCheckin = true;
            break;
          }
        } catch (_) {}
      }
    }
    if (hasAnyCheckin) {
      allMonthlyRecords.add(dateStr);
    }
  }

  // 计算每个项目的最佳连续天数
  int bestConsecutiveDays = 0;
  for (final itemData in itemsList) {
    if (itemData is! Map<String, dynamic>) continue;
    final itemId = itemData['id'] as String?;
    if (plugin != null && itemId != null) {
      try {
        final item = plugin.checkinItems.firstWhere(
          (i) => i.id == itemId,
          orElse: () => throw Exception('项目不存在'),
        );
        final itemBest = _getBestStreak(item);
        if (itemBest > bestConsecutiveDays) {
          bestConsecutiveDays = itemBest;
        }
      } catch (_) {}
    }
  }

  return {
    // MultiMetricProgressCard - 多指标进度卡片
    'multiMetricProgressCard': {
      'trackers': checkinItemCards.map((card) {
        final consecutiveDays = card['isCheckedToday']
            ? (plugin?.checkinItems.firstWhere(
                  (i) => i.id == card['id'],
                  orElse: () => throw Exception(''),
                ).getConsecutiveDays() ?? 0)
            : 0;
        return {
          'emoji': String.fromCharCode(card['iconCodePoint'] as int),
          'progress': (consecutiveDays / 30 * 100).clamp(0, 100).toDouble(),
          'progressColor': card['color'],
          'title': card['title'],
          'subtitle': card['subtitle'],
          'value': consecutiveDays.toDouble(),
          'unit': '天',
        };
      }).toList(),
    },

    // TaskProgressCard - 任务进度卡片
    'taskProgressCard': {
      'title': '打卡进度',
      'subtitle': '本月完成度',
      'completedTasks': todayCheckedCount,
      'totalTasks': itemsList.length,
      'pendingTasks': checkinItemCards
          .where((card) => !(card['isCheckedToday'] as bool))
          .map((card) => card['title'] as String)
          .toList(),
    },

    // CircularMetricsCard - 环形指标卡片
    'circularMetricsCard': {
      'title': '打卡概览',
      'metrics': checkinItemCards.map((card) {
        final consecutiveDays = card['isCheckedToday']
            ? (plugin?.checkinItems.firstWhere(
                  (i) => i.id == card['id'],
                  orElse: () => throw Exception(''),
                ).getConsecutiveDays() ?? 0)
            : 0;
        return {
          'icon': card['iconCodePoint'],
          'value': card['isCheckedToday'] ? '已打卡' : '未打卡',
          'label': card['title'],
          'progress': (consecutiveDays / 30).clamp(0, 1).toDouble(),
          'color': card['color'],
        };
      }).toList(),
    },

    // WatchProgressCard - 观看进度卡片（复用为打卡进度）
    'watchProgressCard': {
      'enableHeader': false,
      'currentCount': monthlyCheckinCount,
      'totalCount': daysInMonth,
      'items': checkinItemCards.map((card) {
        return {
          'title': card['title'],
          'thumbnailUrl': null, // 签到项目没有缩略图
        };
      }).toList(),
    },

    // TaskListCard - 任务列表卡片
    'taskListCard': {
      'icon': '0xe24f', // Icons.checklist - 需要字符串格式
      'iconBackgroundColor': 0xFF14B8A6,
      'count': todayCheckedCount,
      'countLabel': '今日已完成',
      'items': checkinItemCards
          .where((card) => card['isCheckedToday'] as bool)
          .map((card) => card['title'] as String)
          .take(4)
          .toList(),
      'moreCount': checkinItemCards
          .where((card) => !(card['isCheckedToday'] as bool))
          .length,
    },

    // ColorTagTaskCard - 彩色标签任务卡片
    'colorTagTaskCard': {
      'taskCount': itemsList.length,
      'label': '打卡项目',
      'tasks': checkinItemCards.map((card) {
        return {
          'title': card['title'],
          'color': card['color'],
          'isCheckedToday': card['isCheckedToday'],
        };
      }).toList(),
      'moreCount': 0,
    },

    // InboxMessageCard - 收件箱消息卡片（复用为最近打卡项目）
    'inboxMessageCard': {
      'title': '签到习惯',  // 自定义小组件标题
      'messages': checkinItemCards.take(5).map((card) {
        // 获取最后打卡时间
        final itemId = card['id'] as String?;
        String timeAgo = '未打卡';
        if (plugin != null && itemId != null) {
          try {
            final item = plugin.checkinItems.firstWhere(
              (i) => i.id == itemId,
              orElse: () => throw Exception(''),
            );
            final lastDate = item.lastCheckinDate;
            if (lastDate != null) {
              final daysAgo = DateTime.now().difference(lastDate).inDays;
              if (daysAgo == 0) {
                timeAgo = '今天';
              } else if (daysAgo == 1) {
                timeAgo = '昨天';
              } else {
                timeAgo = '$daysAgo天前';
              }
            }
          } catch (_) {}
        }

        return {
          'name': card['title'] as String? ?? '签到项目',
          'avatarUrl': '',  // 空字符串，使用图标代替
          'iconCodePoint': card['iconCodePoint'] as int?,
          'iconBackgroundColor': card['color'] as int?,
          'preview': card['subtitle'] as String? ?? '签到',
          'timeAgo': timeAgo,
        };
      }).toList(),
      'totalCount': checkinItemCards.length,
      'remainingCount': (checkinItemCards.length - 5).clamp(0, 999),
      'primaryColor': 0xFF14B8A6,  // 标题栏背景色（青色）
    },

    // RoundedTaskListCard - 圆角任务列表卡片
    'roundedTaskListCard': {
      'tasks': checkinItemCards.map((card) {
        final consecutiveDays = card['isCheckedToday']
            ? (plugin?.checkinItems.firstWhere(
                  (i) => i.id == card['id'],
                  orElse: () => throw Exception(''),
                ).getConsecutiveDays() ?? 0)
            : 0;
        return {
          'title': card['title'],
          'subtitle': card['subtitle'],
          'date': '连续$consecutiveDays天',
        };
      }).toList(),
      'headerText': '打卡项目',
    },

    // DailyTodoListWidget - 每日待办事项卡片（枚举名是 dailyTodoListCard）
    'dailyTodoListCard': {
      'date': '${_getWeekdayName(today.weekday)}, ${today.day} ${_getMonthName(today.month)} ${today.year}',
      'time': '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}',
      'tasks': checkinItemCards.map((card) {
        return {
          'title': card['title'],
          'isCompleted': card['isCheckedToday'],
        };
      }).toList(),
      'reminder': {
        'text': '今日打卡目标',
        'hashtag': '#习惯养成',
        'hashtagEmoji': '💪',
      },
    },

    // RoundedRemindersList - 圆角提醒事项列表
    'roundedRemindersList': {
      'itemCount': itemsList.length,
      'items': checkinItemCards.map((card) {
        final status = card['isCheckedToday'] ? '✅ ' : '⏰ ';
        return {
          'text': '$status${card['title']}',
          'isCompleted': card['isCheckedToday'],
        };
      }).toList(),
    },
  };
}
