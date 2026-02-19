/// 纪念日插件 - 日期范围列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../day_plugin.dart';
import '../controllers/day_controller.dart';
import '../models/memorial_day.dart';
import 'providers.dart';
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
        return _DateRangeListWidget(
          config: config,
          widgetDefinition: registry.getWidget('day_date_range_list')!,
        );
      },
    ),
  );
}

/// 纪念日列表小组件 - 使用事件携带数据模式
class _DateRangeListWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _DateRangeListWidget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_DateRangeListWidget> createState() => _DateRangeListWidgetState();
}

class _DateRangeListWidgetState extends State<_DateRangeListWidget> {
  /// 缓存的纪念日列表数据（从事件中获取）
  List<MemorialDay>? _cachedMemorialDays;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// 加载初始数据
  void _loadInitialData() {
    final plugin = DayPlugin.instance;
    _cachedMemorialDays = plugin.getAllMemorialDays();
    debugPrint('[DateRangeList] Initial load: ${_cachedMemorialDays?.length ?? 0} items');
  }

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['memorial_day_cache_updated'],
      onEventWithData: (args) {
        if (args is MemorialDayCacheUpdatedEventArgs) {
          debugPrint('[DateRangeList] Received cache_updated: ${args.items.length} items');
          setState(() {
            _cachedMemorialDays = args.items;
          });
        }
      },
      child: _buildContent(),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    final config = widget.config;

    // 解析选择器配置获取日期范围
    int? startDay;
    int? endDay;
    String title = '未来7天';

    try {
      final selectorConfig = config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData = selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            final selectedItem = dataArray[0];
            Map<String, dynamic>? rangeData;

            if (selectedItem is Map<String, dynamic> && selectedItem.containsKey('rawData')) {
              rangeData = selectedItem['rawData'] as Map<String, dynamic>?;
            } else if (selectedItem is Map<String, dynamic>) {
              rangeData = selectedItem;
            }

            if (rangeData != null) {
              startDay = rangeData['startDay'] as int?;
              endDay = rangeData['endDay'] as int?;
              title = rangeData['title'] as String? ?? '未来7天';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[DateRangeList] 解析配置失败: $e');
    }

    debugPrint('[DateRangeList] Building with startDay: $startDay, endDay: $endDay, cached: ${_cachedMemorialDays?.length ?? 0} items');

    // 使用缓存的纪念日数据
    final allDays = _cachedMemorialDays ?? [];
    if (allDays.isEmpty) {
      return _buildEmpty(context);
    }

    // 过滤纪念日
    final filteredDays = filterMemorialDaysByDaysRange(allDays, startDay, endDay);

    debugPrint('[DateRangeList] Filtered ${filteredDays.length} from ${allDays.length} total');

    // 构建数据
    final daysList = filteredDays.map(memorialDayToListItemData).map((d) => d.toJson()).toList();
    final data = {
      'startDay': startDay,
      'endDay': endDay,
      'dateRangeLabel': title,
      'daysList': daysList,
      'totalCount': filteredDays.length,
      'todayCount': filteredDays.where((d) => d.isToday).length,
      'upcomingCount': filteredDays.where((d) => !d.isExpired && !d.isToday).length,
      'expiredCount': filteredDays.where((d) => d.isExpired).length,
    };

    // 使用 FutureBuilder 异步获取公共小组件
    return FutureBuilder<Map<String, dynamic>>(
      future: provideDateRangeCommonWidgets(data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(context);
        }

        if (snapshot.hasError) {
          return HomeWidget.buildErrorWidget(context, snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmpty(context);
        }

        return _buildWithLiveData(context, snapshot.data!);
      },
    );
  }

  /// 使用实时数据构建组件
  Widget _buildWithLiveData(BuildContext context, Map<String, dynamic> liveData) {
    final config = widget.config;
    final widgetDefinition = widget.widgetDefinition;

    // 解析选择器配置
    Map<String, dynamic>? selectorConfig;
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        selectorConfig = config['selectorWidgetConfig'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[DateRangeList] 解析配置失败: $e');
    }

    // 获取小组件尺寸
    final size = config['widgetSize'] as HomeWidgetSize? ?? widgetDefinition.defaultSize;

    // 检查是否使用公共小组件
    final commonWidgetId = selectorConfig?['commonWidgetId'] as String?;
    if (commonWidgetId != null) {
      final widgetData = liveData[commonWidgetId] as Map<String, dynamic>?;
      if (widgetData == null) {
        return HomeWidget.buildErrorWidget(context, '数据不存在');
      }

      // 合并配置
      final savedProps = selectorConfig?['commonWidgetProps'] as Map<String, dynamic>? ?? {};
      final mergedProps = {...savedProps, ...widgetData};

      // 处理 custom 尺寸
      final finalProps = Map<String, dynamic>.from(mergedProps);
      if (size == const CustomSize(width: -1, height: -1)) {
        finalProps['customWidth'] = config['customWidth'] as int?;
        finalProps['customHeight'] = config['customHeight'] as int?;
      }

      // 传递 _pixelCategory
      final pixelCategory = config['_pixelCategory'];
      if (pixelCategory != null) {
        finalProps['_pixelCategory'] = pixelCategory;
      }

      // 将字符串 ID 转换为枚举值
      final commonWidgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
      if (commonWidgetIdEnum == null) {
        return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
      }

      // 使用公共小组件构建器
      return CommonWidgetBuilder.build(context, commonWidgetIdEnum, finalProps, size, inline: true);
    }

    return HomeWidget.buildErrorWidget(context, '未配置渲染方式');
  }

  /// 构建加载状态
  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmpty(BuildContext context) {
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
            Icon(Icons.calendar_month, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('暂无纪念日', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
