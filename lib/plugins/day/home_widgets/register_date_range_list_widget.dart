/// 纪念日插件 - 日期范围列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import '../day_plugin.dart';
import 'providers.dart';
// 导入 utils 以使用 filterMemorialDaysByDaysRange 和 memorialDayToListItemData
import 'utils.dart';

/// 注册纪念日列表小组件 - 显示指定日期范围内的纪念日
void registerDateRangeListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_date_range_list',
      pluginId: 'day',
      name: 'day_listWidgetName'.tr,
      description: 'day_listWidgetDescription'.tr,
      icon: Icons.calendar_month,
      color: Colors.black87,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      // 使用日期范围选择器
      selectorId: 'day.dateRange',
      dataSelector: extractDateRangeData,
      navigationHandler: navigateToDayPage,
      // 使用公共小组件提供者
      commonWidgetsProvider: provideDateRangeCommonWidgets,
      builder: (context, config) {
        // 使用 LiveSelectorWidget 实现实时数据获取
        return _DateRangeListWidget(
          config: config,
          widgetDefinition: registry.getWidget('day_date_range_list')!,
        );
      },
    ),
  );
}

/// 内部 StatefulWidget 使用 LiveSelectorWidget 实现实时数据获取
class _DateRangeListWidget extends LiveSelectorWidget {
  const _DateRangeListWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'memorial_day_added',
    'memorial_day_updated',
    'memorial_day_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    try {
      // 从配置中提取日期范围参数
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData =
            selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            // 从 dataArray 中获取日期范围参数
            final selectedItem = dataArray[0];
            Map<String, dynamic>? rangeData;

            if (selectedItem is Map<String, dynamic> && selectedItem.containsKey('rawData')) {
              rangeData = selectedItem['rawData'] as Map<String, dynamic>?;
            } else if (selectedItem is Map<String, dynamic>) {
              rangeData = selectedItem;
            }

            if (rangeData != null) {
              // 获取 startDay、endDay 和 title
              final startDay = rangeData['startDay'] as int?;
              final endDay = rangeData['endDay'] as int?;
              final title = rangeData['title'] as String? ?? '未来7天';

              debugPrint('[${widgetTag}] Refreshing date range: $title, startDay: $startDay, endDay: $endDay');

              // 从 plugin 重新获取最新的纪念日列表数据
              final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
              debugPrint('[${widgetTag}] Plugin instance hash: ${plugin.hashCode}');
              final allDays = plugin?.getAllMemorialDays() ?? [];
              final filteredDays = filterMemorialDaysByDaysRange(
                allDays,
                startDay,
                endDay,
              );

              debugPrint('[${widgetTag}] Filtered ${filteredDays.length} memorial days from ${allDays.length} total');

              // 将纪念日列表转换为 Map 数组
              final daysList =
                  filteredDays.map(memorialDayToListItemData).map((d) => d.toJson()).toList();

              final data = {
                'startDay': startDay,
                'endDay': endDay,
                'dateRangeLabel': title,
                'daysList': daysList,
                'totalCount': filteredDays.length,
                'todayCount': filteredDays.where((d) => d.isToday).length,
                'upcomingCount':
                    filteredDays.where((d) => !d.isExpired && !d.isToday).length,
                'expiredCount': filteredDays.where((d) => d.isExpired).length,
              };

              return await provideDateRangeCommonWidgets(data);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[${widgetTag}] getLiveData error: $e');
    }
    return {};
  }

  @override
  String get widgetTag => 'DateRangeList';

  /// 从配置中提取日期范围数据
  Map<String, dynamic> _extractDateRangeData(Map<String, dynamic> config) {
    try {
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData =
            selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            // 使用 extractDateRangeData 处理日期范围数据
            return extractDateRangeData(dataArray);
          }
        }
      }
    } catch (e) {
      debugPrint('[DateRangeList] 提取数据失败: $e');
    }
    return {};
  }

  /// 自定义空状态（显示"暂无纪念日"）
  @override
  Widget buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无纪念日',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
