part of 'home_widgets.dart';

/// 获取当月签到天数
int _getMonthlyCheckinCount(CheckinItem? item) {
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
List<Map<String, dynamic>> _generateMonthlyDotsData(
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
int _getBestStreak(CheckinItem? item) {
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
List<Map<String, dynamic>> _generateMilestones(int currentStreak) {
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
List<Map<String, dynamic>> _generateWeekProgressFromMonday(
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
Map<String, dynamic> _extractCheckinItemData(List<dynamic> dataArray) {
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
Map<String, dynamic> _extractCheckinsData(List<dynamic> dataArray) {
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

/// 获取可用的统计项
List<StatItemData> _getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
    if (plugin == null) return [];

    final todayCheckins = plugin.getTodayCheckins();
    final totalItems = plugin.checkinItems.length;
    final totalCheckins = plugin.getTotalCheckins();

    return [
      StatItemData(
        id: 'today_checkin',
        label: 'checkin_todayCheckin'.tr,
        value: '$todayCheckins/$totalItems',
        highlight: todayCheckins > 0,
        color: Colors.teal,
      ),
      StatItemData(
        id: 'total_count',
        label: 'checkin_totalCheckinCount'.tr,
        value: '$totalCheckins',
        highlight: false,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 构建 2x2 详细卡片组件
Widget _buildOverviewWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取可用的统计项数据
    final availableItems = _getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'checkin',
      pluginName: 'checkin_name'.tr,
      pluginIcon: Icons.checklist,
      pluginDefaultColor: Colors.teal,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 导航到签到项目详情
void _navigateToCheckinItem(
  BuildContext context,
  SelectorResult result,
) {
  // 从 result.data 获取已转换的数据（由 dataSelector 处理）
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};
  final itemId = data['id'] as String?;

  if (itemId != null) {
    NavigationHelper.pushNamed(
      context,
      '/checkin/item',
      arguments: {'itemId': itemId},
    );
  }
}

/// 导航到签到项目列表（多选模式）
void _navigateToCheckinItems(
  BuildContext context,
  SelectorResult result,
) {
  // 多选模式默认导航到签到主列表
  NavigationHelper.pushNamed(context, '/checkin');
}

/// 获取星期名称
String _getWeekdayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

/// 获取月份名称
String _getMonthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return names[month - 1];
}
