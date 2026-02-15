/// 日历插件 - 事件列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../models/event.dart';
import 'providers.dart';

/// 日历插件颜色
const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

/// 注册事件列表组件
void registerEventListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_event_list',
      pluginId: 'calendar',
      name: 'calendar_eventListName'.tr,
      description: 'calendar_eventListDesc'.tr,
      icon: Icons.event,
      color: _calendarColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildEventListWidget(context),
    ),
  );
}

/// 构建 2x2 事件列表组件
Widget _buildEventListWidget(BuildContext context) {
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
Widget _buildEventListContent(BuildContext context, ThemeData theme) {
  // 获取最新的日历数据
  final events = getUpcomingEvents(5);
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
                    if (events.isNotEmpty)
                      ...events.map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildEventItem(context, theme, event, timeFormat),
                          ))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'calendar_emptyEvents'.tr,
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

/// 构建单个事件项
Widget _buildEventItem(
  BuildContext context,
  ThemeData theme,
  CalendarEvent event,
  DateFormat timeFormat,
) {
  return Row(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeFormat.format(event.startTime),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      // 图标
      Icon(
        event.icon,
        size: 16,
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    ],
  );
}

/// 跳转到日历页面
void _navigateToCalendar(BuildContext context) {
  NavigationHelper.pushNamed(context, '/calendar');
}
