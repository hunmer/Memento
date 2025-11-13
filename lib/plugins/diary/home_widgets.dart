import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'diary_plugin.dart';
import 'l10n/diary_localizations.dart';

/// 日记插件的主页小组件注册
class DiaryHomeWidgets {
  /// 注册所有日记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'diary_icon',
      pluginId: 'diary',
      name: '日记',
      description: '快速打开日记',
      icon: Icons.book,
      color: Colors.indigo,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'diary_overview',
      pluginId: 'diary',
      name: '日记概览',
      description: '显示今日字数和本月进度',
      icon: Icons.menu_book,
      color: Colors.indigo,
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
        Icons.book,
        size: 48,
        color: Colors.indigo,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = DiaryLocalizations.of(context);

      return FutureBuilder<(int, int, int, int)>(
        future: Future.wait([
          plugin.getTodayWordCount(),
          plugin.getMonthWordCount(),
          plugin.getMonthProgress().then((value) => value.$1),
          plugin.getMonthProgress().then((value) => value.$2),
        ]).then((values) => (values[0], values[1], values[2], values[3])),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todayCount = snapshot.data?.$1 ?? 0;
          final monthCount = snapshot.data?.$2 ?? 0;
          final completedDays = snapshot.data?.$3 ?? 0;
          final totalDays = snapshot.data?.$4 ?? DateTime.now().day;

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
                        color: Colors.indigo.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        size: 24,
                        color: Colors.indigo,
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
                      // 第一行：今日字数和本月字数
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.todayWordCount,
                            value: '$todayCount',
                            theme: theme,
                            highlight: todayCount > 0,
                            color: Colors.indigo,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.dividerColor,
                          ),
                          _StatItem(
                            label: l10n.monthWordCount,
                            value: '$monthCount',
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 第二行：本月进度
                      _StatItem(
                        label: l10n.monthProgress,
                        value: '$completedDays/$totalDays',
                        theme: theme,
                        highlight: completedDays > 0,
                        color: Colors.indigo,
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
