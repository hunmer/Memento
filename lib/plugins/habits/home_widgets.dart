import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'habits_plugin.dart';
import 'l10n/habits_localizations.dart';

/// 习惯追踪插件的主页小组件注册
class HabitsHomeWidgets {
  /// 注册所有习惯追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'habits_icon',
      pluginId: 'habits',
      name: '习惯追踪',
      description: '快速打开习惯追踪',
      icon: Icons.auto_awesome,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'habits_overview',
      pluginId: 'habits',
      name: '习惯概览',
      description: '显示习惯和技能统计',
      icon: Icons.trending_up,
      color: Colors.amber,
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
        Icons.auto_awesome,
        size: 48,
        color: Colors.amber,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = HabitsLocalizations.of(context);

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
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: Colors.amber,
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
              child: FutureBuilder<Map<String, int>>(
                future: _getStatistics(plugin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final stats = snapshot.data ?? {
                    'habits': 0,
                    'skills': 0,
                    'activeTimers': 0,
                  };

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 第一行：习惯数和技能数
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.habits,
                            value: '${stats['habits']}',
                            theme: theme,
                            highlight: stats['habits']! > 0,
                            color: Colors.amber,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.dividerColor,
                          ),
                          _StatItem(
                            label: l10n.skills,
                            value: '${stats['skills']}',
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 第二行：活动计时器数
                      _StatItem(
                        label: '活动计时器',
                        value: '${stats['activeTimers']}',
                        theme: theme,
                        highlight: stats['activeTimers']! > 0,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 获取统计数据
  static Future<Map<String, int>> _getStatistics(HabitsPlugin plugin) async {
    final habitController = plugin.getHabitController();
    final skillController = plugin.getSkillController();
    final timerController = plugin.timerController;

    final habitCount = habitController.getHabits().length;
    final skillCount = skillController.getSkills().length;
    final activeTimers = timerController.getActiveTimers();
    final activeTimerCount = activeTimers.values.where((v) => v).length;

    return {
      'habits': habitCount,
      'skills': skillCount,
      'activeTimers': activeTimerCount,
    };
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
