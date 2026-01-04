import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/app_initializer.dart' show navigatorKey;
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'day_plugin.dart';
import 'models/memorial_day.dart';

/// 纪念日插件的主页小组件注册
class DayHomeWidgets {
  /// 注册所有纪念日插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'day_icon',
        pluginId: 'day',
        name: 'day_widgetName'.tr,
        description: 'day_widgetDescription'.tr,
        icon: Icons.event_outlined,
        color: Colors.black87,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildIconWidget(context),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'day_overview',
        pluginId: 'day',
        name: 'day_overviewName'.tr,
        description: 'day_overviewDescription'.tr,
        icon: Icons.event,
        color: Colors.black87,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 纪念日快捷入口 - 选择纪念日后显示倒计时
    registry.register(
      HomeWidget(
        id: 'day_memorial_selector',
        pluginId: 'day',
        name: 'day_memorialSelectorName'.tr,
        description: 'day_memorialSelectorDescription'.tr,
        icon: Icons.celebration,
        color: Colors.black87,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'day.memorial',
        dataSelector: _extractMemorialDayData,
        dataRenderer: _renderMemorialDayData,
        navigationHandler: _navigateToMemorialDay,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('day_memorial_selector')!,
              config: config,
            ),
      ),
    );

    // 纪念日列表小组件 - 显示指定日期范围内的纪念日
    registry.register(
      HomeWidget(
        id: 'day_date_range_list',
        pluginId: 'day',
        name: 'day_listWidgetName'.tr,
        description: 'day_listWidgetDescription'.tr,
        icon: Icons.calendar_month,
        color: Colors.black87,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        // 使用日期范围选择器
        selectorId: 'day.dateRange',
        dataSelector: _extractDateRangeData,
        dataRenderer: _renderDateRangeList,
        navigationHandler: _navigateToDayPage,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('day_date_range_list')!,
              config: config,
            ),
      ),
    );
  }

  /// 从选择器数据中提取日期范围值
  static Map<String, dynamic> _extractDateRangeData(List<dynamic> dataArray) {
    // dataArray 包含 SelectableItem 对象， rawData 是 Map
    final selectedItem = dataArray[0];

    Map<String, dynamic>? rangeData;
    if (selectedItem is SelectableItem) {
      rangeData = selectedItem.rawData as Map<String, dynamic>?;
    } else if (selectedItem is Map<String, dynamic>) {
      rangeData = selectedItem;
    }

    // 默认值：未来7天
    final startDay = rangeData?['startDay'] as int? ?? 0;
    final endDay = rangeData?['endDay'] as int? ?? 7;
    final title = rangeData?['title'] as String? ?? '未来7天';

    return {
      'startDay': startDay,
      'endDay': endDay,
      'dateRangeLabel': title,
    };
  }

  /// 渲染日期范围列表数据
  static Widget _renderDateRangeList(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final savedData = result.data as Map<String, dynamic>;
    final startDay = savedData['startDay'] as int? ?? 0;
    final endDay = savedData['endDay'] as int? ?? 7;

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'memorial_day_added',
            'memorial_day_updated',
            'memorial_day_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildDateRangeListContent(
            context,
            startDay,
            endDay,
            savedData['dateRangeLabel'] as String? ?? '未来7天',
            config,
          ),
        );
      },
    );
  }

  /// 导航到纪念日主页面
  static void _navigateToDayPage(BuildContext context, SelectorResult result) {
    NavigationHelper.pushNamed(context, '/day');
  }

  /// 从选择器数据中提取小组件需要的数据
  static Map<String, dynamic> _extractMemorialDayData(List<dynamic> dataArray) {
    final dayData = dataArray[0];

    // 处理 MemorialDay 对象或 Map
    if (dayData is MemorialDay) {
      return {
        'id': dayData.id,
        'title': dayData.title,
        'targetDate': dayData.targetDate.toIso8601String(),
        'backgroundImageUrl': dayData.backgroundImageUrl,
      };
    } else if (dayData is Map<String, dynamic>) {
      return {
        'id': dayData['id'] as String,
        'title': dayData['title'] as String?,
        'targetDate': dayData['targetDate'] as String?,
        'backgroundImageUrl': dayData['backgroundImageUrl'] as String?,
      };
    }

    return {};
  }

  /// 渲染纪念日小组件数据 - 显示倒计时信息
  static Widget _renderMemorialDayData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从 result.data 获取已保存的数据
    final savedData =
        result.data is Map
            ? Map<String, dynamic>.from(result.data as Map)
            : <String, dynamic>{};
    final dayId = savedData['id'] as String? ?? '';

    if (dayId.isEmpty) {
      return _buildErrorWidget(context, '未选择纪念日');
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'memorial_day_added',
            'memorial_day_updated',
            'memorial_day_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildMemorialDayWidget(context, dayId, savedData),
        );
      },
    );
  }

  /// 构建纪念日小组件内容（获取最新数据）
  static Widget _buildMemorialDayWidget(
    BuildContext context,
    String dayId,
    Map<String, dynamic> savedData,
  ) {
    // 从 PluginManager 获取最新的纪念日数据
    final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, '纪念日插件不可用');
    }

    // 获取最新数据
    final day = plugin.getMemorialDayById(dayId);
    final title = day?.title ?? savedData['title'] as String? ?? '未知纪念日';
    final targetDateStr =
        day?.targetDate.toIso8601String() ?? savedData['targetDate'] as String?;
    final targetDate =
        targetDateStr != null ? DateTime.tryParse(targetDateStr) : null;
    final daysRemaining = day?.daysRemaining ?? 0;
    final isToday = day?.isToday ?? false;
    final isExpired = day?.isExpired ?? false;
    // 获取背景图片URL（优先使用最新的）
    final backgroundImageUrl =
        day?.backgroundImageUrl ?? savedData['backgroundImageUrl'] as String?;
    // 获取背景色（如果没有图片，使用背景色）
    final backgroundColor = day?.backgroundColor;

    // 计算倒计时文本和颜色
    String countdownText;
    Color countdownColor;
    if (isToday) {
      countdownText = '就是今天！';
      countdownColor = Colors.red;
    } else if (isExpired) {
      countdownText = '已过 ${day?.daysPassed ?? 0} 天';
      countdownColor = Colors.grey;
    } else {
      countdownText = '剩余 $daysRemaining 天';
      countdownColor = Colors.orange;
    }

    return _buildMemorialDayCard(
      context: context,
      title: title,
      countdownText: countdownText,
      countdownColor: countdownColor,
      targetDate: targetDate,
      backgroundImageUrl: backgroundImageUrl,
      backgroundColor: backgroundColor,
    );
  }

  /// 构建纪念日卡片 UI
  static Widget _buildMemorialDayCard({
    required BuildContext context,
    required String title,
    required String countdownText,
    required Color countdownColor,
    required DateTime? targetDate,
    required String? backgroundImageUrl,
    required Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final formattedDate =
        targetDate != null ? '${targetDate.month}月${targetDate.day}日' : '';

    // 获取背景图片路径
    final imagePath =
        backgroundImageUrl != null && backgroundImageUrl.isNotEmpty
            ? ImageUtils.getLocalPath(backgroundImageUrl)
            : null;

    // 决定是否使用图片背景
    final useImageBackground = imagePath != null && imagePath.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // 使用背景图片或渐变背景
            image:
                useImageBackground
                    ? DecorationImage(
                      image: ImageUtils.createImageProvider(backgroundImageUrl),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          // 根据是否有背景图片添加不同的叠加层
          child: Container(
            decoration: BoxDecoration(
              color: useImageBackground ? Colors.black.withOpacity(0.4) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部：图标和标题
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            useImageBackground
                                ? Colors.white.withOpacity(0.25)
                                : theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.celebration,
                        size: 20,
                        color:
                            useImageBackground
                                ? Colors.white
                                : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  useImageBackground
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // 日期（副标题）
                          if (formattedDate.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color:
                                      useImageBackground
                                          ? Colors.white70
                                          : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        useImageBackground
                                            ? Colors.white70
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 底部：倒计时
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      countdownText,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color:
                            useImageBackground ? Colors.white : countdownColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 导航到纪念日详情页
  static void _navigateToMemorialDay(
    BuildContext context,
    SelectorResult result,
  ) {
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final dayId = data['id'] as String?;

    // 使用 navigatorKey.currentContext 确保导航正常工作
    final navContext = navigatorKey.currentContext ?? context;

    NavigationHelper.pushNamed(
      navContext,
      '/day',
      arguments: {'memorialDayId': dayId},
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
      if (plugin == null) return [];

      final totalCount = plugin.getMemorialDayCount();
      final upcomingDays = plugin.getUpcomingMemorialDays();

      return [
        StatItemData(
          id: 'total_count',
          label: 'day_memorialDays'.tr,
          value: '$totalCount',
          highlight: false,
        ),
        StatItemData(
          id: 'upcoming',
          label: 'day_upcoming'.tr,
          value: upcomingDays.isNotEmpty ? upcomingDays.join('、') : '暂无',
          highlight: upcomingDays.isNotEmpty,
          color: Colors.black87,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return GenericIconWidget(
      icon: Icons.event_outlined,
      color: Colors.black87,
      name: 'day_widgetName'.tr,
    );
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
        pluginId: 'day',
        pluginName: 'day_name'.tr,
        pluginIcon: Icons.event_outlined,
        pluginDefaultColor: Colors.black87,
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

  // ===== 日期范围列表小组件 =====

  /// 构建日期范围列表内容
  static Widget _buildDateRangeListContent(
    BuildContext context,
    int startDay,
    int endDay,
    String dateRangeLabel,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, '纪念日插件不可用');
    }

    // 获取所有纪念日并过滤
    final allDays = plugin.getAllMemorialDays();
    final filteredDays = _filterMemorialDaysByDaysRange(allDays, startDay, endDay);

    // 获取小组件尺寸
    final widgetSize = config['widgetSize'] as HomeWidgetSize?;
    final isMediumSize = widgetSize == HomeWidgetSize.medium;

    // 限制显示数量
    final displayDays = filteredDays.take(isMediumSize ? 3 : 5).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // 点击跳转到纪念日主页面
          NavigationHelper.pushNamed(context, '/day');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题和筛选器标签
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'day_listWidgetName'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          dateRangeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 纪念日数量徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredDays.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 纪念日列表（使用滚动容器防止溢出）
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayDays.isNotEmpty) ...[
                        ...displayDays.map((day) => _buildMemorialDayListItem(context, day)),
                        if (filteredDays.length > displayDays.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'day_andMore'.trParams({'count': '${filteredDays.length - displayDays.length}'}),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                              ),
                            ),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'day_noMemorialDaysInRange'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单个纪念日列表项
  static Widget _buildMemorialDayListItem(BuildContext context, MemorialDay day) {
    final theme = Theme.of(context);

    // 计算状态文本和颜色
    String statusText;
    Color statusColor;

    if (day.isToday) {
      statusText = 'day_daysRemaining_zero'.tr;
      statusColor = Colors.red;
    } else if (day.isExpired) {
      statusText = 'day_daysPassed'.trParams({'count': '${day.daysPassed}'});
      statusColor = Colors.grey;
    } else {
      statusText = 'day_daysRemaining'.trParams({'count': '${day.daysRemaining}'});
      statusColor = day.daysRemaining <= 7 ? Colors.orange : theme.colorScheme.primary;
    }

    // 格式化日期
    final formattedDate = '${day.targetDate.month}/${day.targetDate.day}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.celebration,
            size: 16,
            color: day.backgroundColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            statusText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 根据天数范围过滤纪念日
  /// startDay: 起始天数（负数=过去，0=今天，正数=未来）
  /// endDay: 结束天数（负数=过去，0=今天，正数=未来）
  static List<MemorialDay> _filterMemorialDaysByDaysRange(
    List<MemorialDay> days,
    int? startDay,
    int? endDay,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return days.where((day) {
      final targetDate = DateTime(
        day.targetDate.year,
        day.targetDate.month,
        day.targetDate.day,
      );
      final daysDiff = targetDate.difference(today).inDays;

      // 如果 startDay 和 endDay 都为 null，显示全部
      if (startDay == null && endDay == null) {
        return true;
      }

      // 检查天数差是否在范围内
      final inRange = (startDay == null || daysDiff >= startDay) &&
          (endDay == null || daysDiff <= endDay);

      return inRange;
    }).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }
}
