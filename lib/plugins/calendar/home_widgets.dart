import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'calendar_plugin.dart';
import 'models/event.dart';

/// 日历插件的主页小组件注册
class CalendarHomeWidgets {
  /// 日历插件颜色
  static const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

  /// 注册所有日历插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'calendar_icon',
        pluginId: 'calendar',
        name: 'calendar_widgetName'.tr,
        description: 'calendar_widgetDescription'.tr,
        icon: Icons.calendar_month,
        color: _calendarColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.calendar_month,
              color: _calendarColor,
              name: 'calendar_widgetName'.tr,
            ),
      ),
    );

    // 1x1 快速添加事件组件
    registry.register(
      HomeWidget(
        id: 'calendar_quick_add',
        pluginId: 'calendar',
        name: 'calendar_quickAddEvent'.tr,
        description: 'calendar_quickAddEventDesc'.tr,
        icon: Icons.add_circle_outline,
        color: _calendarColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildQuickAddWidget(context, config),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'calendar_overview',
        pluginId: 'calendar',
        name: 'calendar_overviewName'.tr,
        description: 'calendar_overviewDescription'.tr,
        icon: Icons.calendar_today,
        color: _calendarColor,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 2x2 七天事件列表组件
    registry.register(
      HomeWidget(
        id: 'calendar_event_list',
        pluginId: 'calendar',
        name: 'calendar_eventListName'.tr,
        description: 'calendar_eventListDesc'.tr,
        icon: Icons.event,
        color: _calendarColor,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildEventListWidget(context, config),
      ),
    );
  }

  // ===== 1x1 快速添加事件小组件 =====

  /// 构建 1x1 快速添加事件组件
  static Widget _buildQuickAddWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToAddEvent(context),
        child: SizedBox.expand(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标在中间，标题在下边，图标右上角带加号 badge
                  Stack(
                    alignment: Alignment.topRight,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.event, size: 40, color: _calendarColor),
                      // 图标右上角加号 badge
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _calendarColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'calendar_quickAddEvent'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 跳转到添加事件页面
  static void _navigateToAddEvent(BuildContext context) {
    try {
      final calendarPlugin =
          PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (calendarPlugin != null) {
        calendarPlugin.showEventEditPage(context);
      }
    } catch (e) {
      debugPrint('[CalendarHomeWidgets] 跳转添加事件失败: $e');
    }
  }

  // ===== 2x2 七天事件列表小组件 =====

  /// 获取未来7天的事件列表
  static List<CalendarEvent> _getUpcomingEvents(int limit) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin != null) {
        final controller = plugin.controller;
        final allEvents = controller.getAllEvents();
        final now = DateTime.now();
        final sevenDaysLater = now.add(const Duration(days: 7));

        // 获取未来7天内的未完成事件
        final upcomingEvents = allEvents.where((event) {
          return event.startTime.isAfter(now) &&
              event.startTime.isBefore(sevenDaysLater) &&
              event.completedTime == null;
        }).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return upcomingEvents.take(limit).toList();
      }
    } catch (e) {
      debugPrint('[CalendarHomeWidgets] 获取事件列表失败: $e');
    }
    return [];
  }

  /// 构建 2x2 事件列表组件
  static Widget _buildEventListWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'calendar_event_added',
            'calendar_event_updated',
            'calendar_event_deleted',
            'calendar_event_completed',
          ],
          onEvent: () => setState(() {}),
          child: _buildEventListContent(context, theme),
        );
      },
    );
  }

  /// 构建事件列表内容（获取最新数据）
  static Widget _buildEventListContent(
    BuildContext context,
    ThemeData theme,
  ) {
    // 从 PluginManager 获取最新的日历数据
    final events = _getUpcomingEvents(5);
    final timeFormat = DateFormat('HH:mm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCalendar(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题
              Row(
                children: [
                  Icon(Icons.event, size: 20, color: _calendarColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'calendar_eventListName'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 事件列表
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (events.isNotEmpty) ...[
                        ...events.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                // 颜色指示器
                                Container(
                                  width: 4,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: event.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        timeFormat.format(event.startTime),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 图标
                                Icon(
                                  event.icon,
                                  size: 16,
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'calendar_emptyEvents'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.5),
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

  /// 跳转到日历页面
  static void _navigateToCalendar(BuildContext context) {
    NavigationHelper.pushNamed(
      context,
      '/calendar',
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) return [];

      final allEvents = plugin.controller.getAllEvents();
      final eventCount = allEvents.length;

      // 获取7天内的活动数量

      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      final upcomingEventCount =
          allEvents.where((event) {
            return event.startTime.isAfter(now) &&
                event.startTime.isBefore(sevenDaysLater);
          }).length;

      // 获取过期活动数量
      final expiredEventCount =
          allEvents.where((event) {
            return event.startTime.isBefore(now);
          }).length;

      return [
        StatItemData(
          id: 'event_count',
          label: 'calendar_activityCount'.tr,
          value: '$eventCount',
          highlight: false,
        ),
        StatItemData(
          id: 'week_events',
          label: 'calendar_sevenDaysActivity'.tr,
          value: '$upcomingEventCount',
          highlight: upcomingEventCount > 0,
          color: Colors.orange,
        ),
        StatItemData(
          id: 'expired_events',
          label: 'calendar_expiredActivity'.tr,
          value: '$expiredEventCount',
          highlight: expiredEventCount > 0,
          color: Colors.red,
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
        pluginId: 'calendar',
        pluginName: 'calendar_name'.tr,
        pluginIcon: Icons.calendar_month,
        pluginDefaultColor: const Color.fromARGB(255, 211, 91, 91),
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
}
