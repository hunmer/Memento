import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'tracker_plugin.dart';
import 'l10n/tracker_localizations.dart';

/// 目标追踪插件的主页小组件注册
class TrackerHomeWidgets {
  /// 注册所有目标追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'tracker_icon',
      pluginId: 'tracker',
      name: '目标追踪',
      description: '快速打开目标追踪',
      icon: Icons.track_changes,
      color: Colors.red,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'tracker_overview',
      pluginId: 'tracker',
      name: '目标追踪概览',
      description: '显示今日和本月完成统计',
      icon: Icons.analytics_outlined,
      color: Colors.red,
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
        Icons.track_changes,
        size: 48,
        color: Colors.red,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = TrackerLocalizations.of(context);

      return FutureBuilder<(int, int)>(
        future: Future.wait([
          Future(() => plugin.controller.getTodayCompletedGoals()),
          Future(() => plugin.controller.getMonthCompletedGoals()),
        ]).then((values) => (values[0], values[1])),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todayComplete = snapshot.data?.$1 ?? 0;
          final monthComplete = snapshot.data?.$2 ?? 0;

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
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.track_changes,
                        size: 24,
                        color: Colors.red,
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
                      // 今日完成和本月完成
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.todayComplete,
                            value: '$todayComplete',
                            theme: theme,
                            highlight: todayComplete > 0,
                            color: Colors.red,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.dividerColor,
                          ),
                          _StatItem(
                            label: l10n.thisMonthComplete,
                            value: '$monthComplete',
                            theme: theme,
                            highlight: monthComplete > 0,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
