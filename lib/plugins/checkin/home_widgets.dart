import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'checkin_plugin.dart';
import 'models/checkin_item.dart';

/// 打卡插件的主页小组件注册
class CheckinHomeWidgets {
  /// 注册所有打卡插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'checkin_icon',
        pluginId: 'checkin',
        name: 'checkin_widgetName'.tr,
        description: 'checkin_widgetDescription'.tr,
        icon: Icons.checklist,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.checklist,
              color: Colors.teal,
              name: 'checkin_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'checkin_overview',
        pluginId: 'checkin',
        name: 'checkin_overviewName'.tr,
        description: 'checkin_overviewDescription'.tr,
        icon: Icons.checklist_rtl,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 签到项目选择器小组件 - 快速访问指定签到项目
    registry.register(
      HomeWidget(
        id: 'checkin_item_selector',
        pluginId: 'checkin',
        name: 'checkin_quickAccess'.tr,
        description: 'checkin_quickAccessDesc'.tr,
        icon: Icons.access_time,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.item',
        navigationHandler: _navigateToCheckinItem,
        dataSelector: _extractCheckinItemData,
        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgets,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('checkin_item_selector')!,
              config: config,
            ),
      ),
    );
  }

  /// 公共小组件提供者函数
  static Map<String, Map<String, dynamic>> _provideCommonWidgets(
    Map<String, dynamic> data,
  ) {
    // data 包含：id, name, group, icon, color
    final name = (data['name'] as String?) ?? '签到项目';
    final group = (data['group'] as String?) ?? '';
    final colorValue = (data['color'] as int?) ?? 0xFF007AFF;
    final iconCode = (data['icon'] as int?) ?? Icons.checklist.codePoint;

    // 获取插件实例以获取实时数据
    final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
    CheckinItem? item;
    int consecutiveDays = 0;
    int todayCheckins = 0;
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
          todayCheckins = item.getTodayRecords().length;
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

      // 心情追踪卡片（复用）：显示本周签到状态
      'moodTrackerCard': {
        'currentEmotionText': isCheckedToday ? '今日已签' : '今日未签',
        'loggedCount': weeklyCheckins,
        'totalCount': 7,
        'weekEmotions': _generateWeekEmotions(item),
      },

      // 月度进度带点卡片：显示当月签到进度
      'monthlyProgressDotsCard': {
        'title': name,
        'subtitle': group.isNotEmpty ? group : '签到',
        'month': '${DateTime.now().month}月',
        'currentDay': DateTime.now().day,
        'year': DateTime.now().year,
        'totalDays': DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day,
        'checkedDays': _getMonthlyCheckinCount(item),
        'daysData': _generateMonthlyDotsData(item),
        'percentage': ((_getMonthlyCheckinCount(item) /
                    DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day) *
                100)
            .toInt(),
      },

      // 睡眠追踪卡片（复用）：显示连续签到天数作为睡眠数据
      'sleepTrackingCard': {
        'title': name,
        'sleepHours': consecutiveDays.toDouble(),
        'sleepGoal': 30.0, // 30天习惯养成
        'deepSleepHours': (consecutiveDays * 0.7).toDouble(), // 约70%的有效天数
        'weekData': List.generate(7, (index) {
          final i = 6 - index;
          final date = DateTime.now().subtract(Duration(days: i));
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final hasRecord = item?.checkInRecords.containsKey(dateStr) == true &&
              (item?.checkInRecords[dateStr]?.isEmpty == false);
          return {
            'day': '周${['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1]}',
            'hours': hasRecord ? (consecutiveDays / 7.0).clamp(0.0, 12.0) : 0.0,
            'hasData': hasRecord,
          };
        }),
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

      // 周度点追踪卡片：显示本周签到状态点
      'weeklyDotTrackerCard': {
        'title': name,
        'subtitle': group.isNotEmpty ? group : '签到',
        'weekData': List.generate(7, (index) {
          final i = 6 - index;
          final date = DateTime.now().subtract(Duration(days: i));
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final hasRecord = item?.checkInRecords.containsKey(dateStr) == true &&
              (item?.checkInRecords[dateStr]?.isEmpty == false);
          return {
            'day': '周${['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1]}',
            'date': date.day,
            'isChecked': hasRecord,
            'isToday': i == 0,
          };
        }),
        'checkedDays': weeklyCheckins,
        'totalDays': 7,
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
          final hasRecord = item?.checkInRecords.containsKey(dateStr) == true &&
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

  /// 获取当月签到天数
  static int _getMonthlyCheckinCount(CheckinItem? item) {
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
  static List<Map<String, dynamic>> _generateMonthlyDotsData(CheckinItem? item) {
    final today = DateTime.now();
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final result = <Map<String, dynamic>>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasRecord = item?.checkInRecords.containsKey(dateStr) == true &&
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
  static int _getBestStreak(CheckinItem? item) {
    if (item == null || item.checkInRecords.isEmpty) return 0;

    final sortedDates = item.checkInRecords.keys.toList()..sort();
    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final dateStr in sortedDates) {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

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
  static List<Map<String, dynamic>> _generateMilestones(int currentStreak) {
    final milestones = [7, 21, 30, 60, 100, 365];
    final result = <Map<String, dynamic>>[];

    for (final milestone in milestones) {
      result.add({
        'days': milestone,
        'label': milestone >= 365 ? '一年' : '$milestone天',
        'isReached': currentStreak >= milestone,
        'isCurrent': currentStreak < milestone &&
            (result.isEmpty || currentStreak > (result.last['days'] as int)),
      });
    }

    return result;
  }

  /// 生成周情绪数据（复用心情追踪卡片的数据结构）
  static List<Map<String, dynamic>> _generateWeekEmotions(CheckinItem? item) {
    final today = DateTime.now();
    final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isChecked =
          item?.checkInRecords.containsKey(dateStr) == true &&
          (item?.checkInRecords[dateStr]?.isEmpty == false);

      result.add({
        'day': weekDays[date.weekday - 1],
        'iconCodePoint': isChecked ? 0xe5ca : 0xe5c8, // check_circle / circle_outlined
        'emotionType': isChecked ? 'positive' : 'neutral',
        'isLogged': isChecked,
      });
    }

    return result;
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractCheckinItemData(List<dynamic> dataArray) {
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

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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
  static Widget _buildOverviewWidget(
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
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 导航到签到项目详情
  static void _navigateToCheckinItem(
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
}
