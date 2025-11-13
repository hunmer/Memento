import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'calendar_album_plugin.dart';
import 'l10n/calendar_album_localizations.dart';

/// 日历相册插件的主页小组件注册
class CalendarAlbumHomeWidgets {
  /// 注册所有日历相册插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'calendar_album_icon',
      pluginId: 'calendar_album',
      name: '日历相册',
      description: '快速打开日历相册',
      icon: Icons.notes_rounded,
      color: const Color.fromARGB(255, 245, 210, 52),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'calendar_album_overview',
      pluginId: 'calendar_album',
      name: '日历相册概览',
      description: '显示日记和标签统计',
      icon: Icons.calendar_today,
      color: const Color.fromARGB(255, 245, 210, 52),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context),
    ));
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.notes_rounded,
        size: 48,
        color: const Color.fromARGB(255, 245, 210, 52),
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar_album')
          as CalendarAlbumPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = CalendarAlbumLocalizations.of(context);

      // 获取统计数据
      final todayCount = plugin.calendarController.getTodayEntriesCount();
      final sevenDayCount =
          plugin.calendarController.getLast7DaysEntriesCount();
      final allEntriesCount = plugin.calendarController.getAllEntriesCount();
      final tagCount = plugin.tagController.tags.length;

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
                    color: const Color.fromARGB(255, 245, 210, 52)
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notes_rounded,
                    size: 24,
                    color: Color.fromARGB(255, 245, 210, 52),
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
                  // 第一行：今日日记和七日日记
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.todayDiary,
                        value: '$todayCount',
                        theme: theme,
                        highlight: todayCount > 0,
                        color: const Color.fromARGB(255, 245, 210, 52),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: theme.dividerColor,
                      ),
                      _StatItem(
                        label: l10n.sevenDayDiary,
                        value: '$sevenDayCount',
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行：所有日记和标签数量
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.allDiaries,
                        value: '$allEntriesCount',
                        theme: theme,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: theme.dividerColor,
                      ),
                      _StatItem(
                        label: l10n.tagCount,
                        value: '$tagCount',
                        theme: theme,
                      ),
                    ],
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
