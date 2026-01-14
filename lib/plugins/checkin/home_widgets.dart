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
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.item',
        dataRenderer: _renderCheckinItemData,
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
      // 圆形进度卡片：显示本周签到进度
      'circularProgressCard': {
        'title': name,
        'subtitle': group.isNotEmpty ? group : '签到',
        'percentage': (weeklyCheckins / 7 * 100).clamp(0, 100).toDouble(),
        'progress': (weeklyCheckins / 7).clamp(0.0, 1.0),
      },

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

      // 任务进度卡片：显示今日签到状态
      'taskProgressCard': {
        'title': name,
        'subtitle': isCheckedToday ? '今日已签' : '今日未签',
        'completedTasks': isCheckedToday ? 1 : 0,
        'totalTasks': 1,
        'pendingTasks': isCheckedToday ? <String>[] : <String>['点击签到'],
      },

      // 里程碑卡片：显示连续签到里程碑
      'milestoneCard': {
        'imageUrl': null,
        'title': name,
        'date': DateTime.now().toString().substring(0, 10),
        'daysCount': consecutiveDays,
        'value': '$consecutiveDays',
        'unit': '天',
        'suffix': consecutiveDays > 0 ? '连续签到' : '开始签到',
      },

      // 观看进度卡片（复用）：显示本周签到详情
      'watchProgressCard': {
        'userName': name,
        'lastWatched': isCheckedToday ? '今日已签到' : '今日未签到',
        'currentCount': weeklyCheckins,
        'totalCount': 7,
        'items': List.generate(
          weeklyCheckins,
          (index) => {'title': '第${weeklyCheckins - index}次签到', 'thumbnailUrl': null},
        ),
      },

      // 每日事件卡片（复用）：显示本周签到状态
      'dailyEventsCard': {
        'events': List.generate(
          weeklyCheckins,
          (index) => {'title': '签到记录', 'time': '已完成'},
        ),
      },

      // 现代 eGFR 健康指标卡片（复用）：显示连续天数
      'modernEgfrHealthWidget': {
        'title': name,
        'value': consecutiveDays.toDouble(),
        'unit': '天',
        'date': DateTime.now().toString().substring(0, 10),
        'status': consecutiveDays >= 30
            ? '习惯养成'
            : consecutiveDays >= 7
                ? '坚持中'
                : consecutiveDays > 0 ? '刚开始' : '未开始',
        'icon': iconCode,
        'primaryColor': colorValue,
        'statusColor': consecutiveDays >= 30 ? 0xFF34C759 : consecutiveDays >= 7 ? 0xFFFFCC00 : 0xFF8E8E93,
      },

      // 图标圆形进度卡片：显示签到进度
      'iconCircularProgressCard': {
        'icon': iconCode,
        'title': name,
        'subtitle': group.isNotEmpty ? group : '签到',
        'percentage': (weeklyCheckins / 7 * 100).clamp(0, 100).toDouble(),
        'progress': (weeklyCheckins / 7).clamp(0.0, 1.0),
        'showNotification': !isCheckedToday,
      },

      // 睡眠时长卡片（复用）：显示今日签到次数作为时长
      'sleepDurationCard': {
        'durationInMinutes': todayCheckins * 60,
        'trend': isCheckedToday ? 'up' : 'neutral',
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

  // ===== 签到项目选择器小组件相关方法 =====

  /// 渲染签到项目数据
  static Widget _renderCheckinItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从初始化数据中获取项目ID
    final itemData = result.data as Map<String, dynamic>;
    final itemId = itemData['id'] as String?;

    if (itemId == null) {
      return _buildErrorWidget(context, '项目不存在');
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['checkin_deleted'],
          onEvent: () => setState(() {}),
          child: _buildCheckinItemWidget(context, itemId, config),
        );
      },
    );
  }

  /// 构建签到项目小组件内容（获取最新数据）
  static Widget _buildCheckinItemWidget(
    BuildContext context,
    String itemId,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的项目数据
    final plugin =
        PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, '插件不可用');
    }

    // 查找对应项目
    CheckinItem? checkinItem;
    try {
      checkinItem = plugin.checkinItems.firstWhere(
        (i) => i.id == itemId,
        orElse: () => throw Exception('项目不存在'),
      );
    } catch (e) {
      return _buildErrorWidget(context, '项目不存在');
    }

    final name = checkinItem.name;
    final group = checkinItem.group;
    final iconCode = checkinItem.icon.codePoint;
    final colorValue = checkinItem.color.value;
    final isCheckedToday = checkinItem.isCheckedToday();
    final itemColor = Color(colorValue);

    // 获取卡片大小
    final widgetSize = config['widgetSize'] as HomeWidgetSize?;
    final showHeatmap =
        widgetSize == HomeWidgetSize.medium ||
        widgetSize == HomeWidgetSize.large;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 习惯图标和标题（占据左上角）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(iconCode, fontFamily: 'MaterialIcons'),
                  color: itemColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group != null)
                      Text(
                        group,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 右上角打卡状态
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isCheckedToday
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isCheckedToday
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedToday
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 14,
                      color: isCheckedToday ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCheckedToday ? '已打卡' : '未打卡',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCheckedToday ? Colors.green : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 热力图（根据卡片大小显示不同范围）
          if (showHeatmap) ...[
            const SizedBox(height: 12),
            _buildHeatmapGrid(context, checkinItem, itemColor, widgetSize!),
          ],
        ],
      ),
    );
  }

  /// 构建热力图网格
  static Widget _buildHeatmapGrid(
    BuildContext context,
    CheckinItem item,
    Color itemColor,
    HomeWidgetSize size,
  ) {
    final today = DateTime.now();
    final List<int> checkStatus = [];
    final List<bool> isChecked = [];

    if (size == HomeWidgetSize.medium) {
      // medium: 显示过去7天
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        checkStatus.add(date.day);
        isChecked.add(
          item.checkInRecords.containsKey(dateStr) &&
              item.checkInRecords[dateStr]!.isNotEmpty,
        );
      }
    } else {
      // large: 显示当月所有日期
      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        checkStatus.add(day);
        isChecked.add(
          item.checkInRecords.containsKey(dateStr) &&
              item.checkInRecords[dateStr]!.isNotEmpty,
        );
      }

      // 居中显示：首尾添加空网格占位
      final daysInMonthMod = daysInMonth % 7;
      if (daysInMonthMod != 0) {
        final emptyCount = 7 - daysInMonthMod;
        final emptyAtStart = emptyCount ~/ 2;
        final emptyAtEnd = emptyCount - emptyAtStart;

        for (int i = 0; i < emptyAtStart; i++) {
          checkStatus.insert(0, 0); // 0表示空网格占位
          isChecked.insert(0, false);
        }
        for (int i = 0; i < emptyAtEnd; i++) {
          checkStatus.add(0);
          isChecked.add(false);
        }
      }
    }

    final crossAxisCount = 7;
    final spacing = size == HomeWidgetSize.medium ? 4.0 : 3.0;
    final showNumber = size == HomeWidgetSize.large;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final totalWidthSpacing = (crossAxisCount - 1) * spacing;
        final cellWidth = (maxWidth - totalWidthSpacing) / crossAxisCount;

        final totalItems = checkStatus.length;
        final rows = (totalItems / crossAxisCount).ceil();

        final totalHeightSpacing = (rows - 1) * spacing;
        final cellHeight = (maxHeight - totalHeightSpacing) / rows;

        final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;
        final fontSize = cellSize * 0.4;

        final totalHeight = rows * cellSize + (rows - 1) * spacing;

        return SizedBox(
          height: totalHeight.clamp(0.0, maxHeight),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: List.generate(checkStatus.length, (index) {
              final day = checkStatus[index];
              final checked = isChecked[index];

              if (day == 0) {
                // 空网格占位
                return SizedBox(width: cellSize, height: cellSize);
              }

              return SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        checked
                            ? itemColor.withOpacity(0.6)
                            : itemColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(cellSize / 3),
                  ),
                  child:
                      showNumber
                          ? Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          : null,
                ),
              );
            }),
          ),
        );
      },
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
