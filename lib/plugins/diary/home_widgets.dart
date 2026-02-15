import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:get/get.dart';
import 'diary_plugin.dart';
import 'models/diary_entry.dart';
import 'utils/diary_utils.dart';
import 'screens/diary_editor_screen.dart';
import 'home_widgets/register_monthly_diary_list.dart';

/// 日记插件的主页小组件注册
class DiaryHomeWidgets {
  /// 注册所有日记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'diary_icon',
        pluginId: 'diary',
        name: 'diary_widgetName'.tr,
        description: 'diary_widgetDescription'.tr,
        icon: Icons.book,
        color: Colors.indigo,
        defaultSize: const SmallSize(),
        supportedSizes: [const SmallSize()],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.book,
              color: Colors.indigo,
              name: 'diary_widgetName'.tr,
            ),
      ),
    );

    // 1x1 今日日记快捷入口
    registry.register(
      HomeWidget(
        id: 'diary_today_quick',
        pluginId: 'diary',
        name: 'diary_todayQuickName'.tr,
        description: 'diary_todayQuickDescription'.tr,
        icon: Icons.edit_calendar,
        color: Colors.indigo,
        defaultSize: const SmallSize(),
        supportedSizes: [const SmallSize()],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.edit_calendar,
              color: Colors.indigo,
              name: 'diary_todayQuickName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'diary_overview',
        pluginId: 'diary',
        name: 'diary_overviewName'.tr,
        description: 'diary_overviewDescription'.tr,
        icon: Icons.menu_book,
        color: Colors.indigo,
        defaultSize: const LargeSize(),
        supportedSizes: [const LargeSize()],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 4x1 宽屏卡片 - 七日日记（占满宽度）
    registry.register(
      HomeWidget(
        id: 'diary_weekly',
        pluginId: 'diary',
        name: 'diary_weeklyName'.tr,
        description: 'diary_weeklyDescription'.tr,
        icon: Icons.calendar_view_week,
        color: Colors.indigo,
        defaultSize: const WideSize()2,
        supportedSizes: [const WideSize(), const WideSize()2],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildWeeklyWidget(context, config),
      ),
    );

    // 本月日记列表展示入口（支持多种通用小组件）
    registerMonthlyDiaryListWidget(registry);
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (plugin == null) return [];

      // 同步获取统计数据
      final todayCount = plugin.getTodayWordCountSync();
      final monthCount = plugin.getMonthWordCountSync();
      final monthProgress = plugin.getMonthProgressSync();

      return [
        StatItemData(
          id: 'today_word_count',
          label: 'diary_todayWordCount'.tr,
          value: '$todayCount',
          highlight: todayCount > 0,
          color: Colors.indigo,
        ),
        StatItemData(
          id: 'month_word_count',
          label: 'diary_monthWordCount'.tr,
          value: '$monthCount',
          highlight: false,
        ),
        StatItemData(
          id: 'month_progress',
          label: 'diary_monthProgress'.tr,
          value: '${monthProgress.$1}/${monthProgress.$2}',
          highlight: monthProgress.$1 > 0,
          color: Colors.indigo,
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
        pluginId: 'diary',
        pluginName: 'diary_name'.tr,
        pluginIcon: Icons.menu_book,
        pluginDefaultColor: Colors.indigo,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }

  /// 构建七日日记小组件
  static Widget _buildWeeklyWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    return FutureBuilder<Map<DateTime, DiaryEntry>>(
      future: DiaryUtils.loadDiaryEntries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? {};
        final now = DateTime.now();
        final weekDays = _getCurrentWeekDays(now);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 七天卡片
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      weekDays.map((date) {
                        final entry = entries[date];
                        return _buildDayCard(context, date, entry);
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取当前周的周一到周日日期
  static List<DateTime> _getCurrentWeekDays(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // Monday = 1, Sunday = 7
    final weekday = normalizedDate.weekday;
    // 计算周一
    final monday = normalizedDate.subtract(Duration(days: weekday - 1));
    // 生成周一到周日的日期列表
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// 构建单日卡片
  static Widget _buildDayCard(
    BuildContext context,
    DateTime date,
    DiaryEntry? entry,
  ) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final weekdayFormat = DateFormat('E');
    final dayFormat = DateFormat('d');

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color:
              isToday
                  ? Colors.indigo.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: Colors.indigo, width: 1.5) : null,
        ),
        child: InkWell(
          onTap: () => _openDiaryEditor(context, date),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 星期几
                Text(
                  weekdayFormat.format(date),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? Colors.indigo : Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                // 日期数字
                Text(
                  dayFormat.format(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.indigo : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // 心情
                if (entry?.mood != null)
                  Text(entry!.mood!, style: const TextStyle(fontSize: 18))
                else
                  const SizedBox(height: 18),
                // 标题（如果有）
                Text(
                  entry?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: entry != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开日记编辑器
  static Future<void> _openDiaryEditor(
    BuildContext context,
    DateTime date,
  ) async {
    final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
    if (plugin == null) return;

    // 加载现有日记（如果存在）
    final entry = await DiaryUtils.loadDiaryEntry(date);

    NavigationHelper.push(
      context,
      DiaryEditorScreen(
        date: date,
        storage: plugin.storage,
        initialTitle: entry?.title ?? '',
        initialContent: entry?.content ?? '',
      ),
    );
  }
}
