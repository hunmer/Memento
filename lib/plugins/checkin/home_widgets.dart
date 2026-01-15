import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
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
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.item',
        navigationHandler: _navigateToCheckinItem,
        dataSelector: _extractCheckinItemData,
        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgets,
        builder: (context, config) {
          // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'checkin_completed', // 打卡完成
                  'checkin_cancelled', // 取消打卡
                  'checkin_reset', // 重置记录
                  'checkin_deleted', // 删除项目
                ],
                onEvent: () => setState(() {}),
                child: HomeWidget.buildDynamicSelectorWidget(
                  context,
                  config,
                  registry.getWidget('checkin_item_selector')!,
                ),
              );
            },
          );
        },
      ),
    );

    // 多选签到项目小组件 - 显示多个签到项目的打卡状态
    registry.register(
      HomeWidget(
        id: 'checkin_items_selector',
        pluginId: 'checkin',
        name: 'checkin_multiQuickAccess'.tr,
        description: 'checkin_multiQuickAccessDesc'.tr,
        icon: Icons.dashboard,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.items',
        navigationHandler: _navigateToCheckinItems,
        dataSelector: _extractCheckinItemsData,
        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgetsForMultiple,
        builder: (context, config) {
          // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'checkin_completed', // 打卡完成
                  'checkin_cancelled', // 取消打卡
                  'checkin_reset', // 重置记录
                  'checkin_deleted', // 删除项目
                ],
                onEvent: () => setState(() {}),
                child: HomeWidget.buildDynamicSelectorWidget(
                  context,
                  config,
                  registry.getWidget('checkin_items_selector')!,
                ),
              );
            },
          );
        },
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
    final plugin =
        PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
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
  static List<Map<String, dynamic>> _generateMonthlyDotsData(
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
  static int _getBestStreak(CheckinItem? item) {
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
  static List<Map<String, dynamic>> _generateMilestones(int currentStreak) {
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
        'iconCodePoint':
            isChecked ? 0xe5ca : 0xe5c8, // check_circle / circle_outlined
        'emotionType': isChecked ? 'positive' : 'neutral',
        'isLogged': isChecked,
      });
    }

    return result;
  }

  /// 生成从周一开始的周进度数据（用于 sleepTrackingCard）
  static List<Map<String, dynamic>> _generateWeekProgressFromMonday(
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
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
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

  /// 导航到签到项目列表（多选模式）
  static void _navigateToCheckinItems(
    BuildContext context,
    SelectorResult result,
  ) {
    // 多选模式默认导航到签到主列表
    NavigationHelper.pushNamed(context, '/checkin');
  }

  /// 从选择器数据数组中提取多个签到项目的数据
  static Map<String, dynamic> _extractCheckinItemsData(List<dynamic> dataArray) {
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

  /// 为多个签到项目提供公共小组件数据
  static Map<String, Map<String, dynamic>> _provideCommonWidgetsForMultiple(
    Map<String, dynamic> data,
  ) {
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

    int totalConsecutiveDays = 0;
    int todayCheckedCount = 0;

    for (final itemData in itemsList) {
      if (itemData is! Map<String, dynamic>) continue;

      final itemId = itemData['id'] as String?;
      final name = (itemData['name'] as String?) ?? '签到项目';
      final group = (itemData['group'] as String?) ?? '';
      final colorValue = (itemData['color'] as int?) ?? 0xFF007AFF;
      final iconCode = (itemData['icon'] as int?) ?? Icons.checklist.codePoint;

      CheckinItem? item;
      int consecutiveDays = 0;
      bool isCheckedToday = false;

      if (plugin != null && itemId != null) {
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

      totalConsecutiveDays += consecutiveDays;
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

    final monthlyProgress = (monthlyCheckinCount / daysInMonth * 100).clamp(0, 100);

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

      // InboxMessageCard - 收件箱消息卡片（复用为最近打卡记录）
      'inboxMessageCard': {
        'messages': allMonthlyRecords.reversed.take(5).map((dateStr) {
          final parts = dateStr.split('-');
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final weekday = ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1];
          return {
            'name': '周$weekday',
            'avatarUrl': null,
            'preview': '$dateStr 打卡记录',
            'timeAgo': '${DateTime.now().difference(date).inDays}天前',
          };
        }).toList(),
        'totalCount': allMonthlyRecords.length,
        'remainingCount': 0,
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

  /// 获取星期名称
  static String _getWeekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  /// 获取月份名称
  static String _getMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}
