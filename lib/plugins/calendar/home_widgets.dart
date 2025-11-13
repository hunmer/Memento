import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'calendar_plugin.dart';
import 'l10n/calendar_localizations.dart';

/// 日历插件的主页小组件注册
class CalendarHomeWidgets {
  /// 注册所有日历插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'calendar_icon',
      pluginId: 'calendar',
      name: '日历',
      description: '快速打开日历',
      icon: Icons.calendar_month,
      color: const Color.fromARGB(255, 211, 91, 91),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'calendar_overview',
      pluginId: 'calendar',
      name: '日历概览',
      description: '显示活动数量、7天活动和过期活动统计',
      icon: Icons.calendar_today,
      color: const Color.fromARGB(255, 211, 91, 91),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context),
    ));
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.calendar_month,
        size: 48,
        color: const Color.fromARGB(255, 211, 91, 91),
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = CalendarLocalizations.of(context);

      // 获取所有活动数量
      final eventCount = plugin.controller.getAllEvents().length;

      // 获取7天内的活动数量
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      final upcomingEventCount = plugin.controller.getAllEvents().where((event) {
        return event.startTime.isAfter(now) &&
            event.startTime.isBefore(sevenDaysLater);
      }).length;

      // 获取过期活动数量
      final expiredEventCount = plugin.controller.getAllEvents().where((event) {
        return event.startTime.isBefore(now);
      }).length;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图标和标题
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 211, 91, 91).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 24,
                    color: Color.fromARGB(255, 211, 91, 91),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 统计信息
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 第一行：活动数量和7天活动
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.eventCount,
                        value: '$eventCount',
                        theme: theme,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: theme.dividerColor,
                      ),
                      _StatItem(
                        label: l10n.weekEvents,
                        value: '$upcomingEventCount',
                        theme: theme,
                        highlight: upcomingEventCount > 0,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行：过期活动
                  _StatItem(
                    label: l10n.expiredEvents,
                    value: '$expiredEventCount',
                    theme: theme,
                    highlight: expiredEventCount > 0,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight && color != null ? color : null,
          ),
        ),
      ],
    );
  }
}
