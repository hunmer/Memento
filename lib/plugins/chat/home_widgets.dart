import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'chat_plugin.dart';
import 'l10n/chat_localizations.dart';

/// 聊天插件的主页小组件注册
class ChatHomeWidgets {
  /// 注册所有聊天插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'chat_icon',
      pluginId: 'chat',
      name: '聊天',
      description: '快速打开聊天',
      icon: Icons.chat_bubble,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '通讯',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'chat_overview',
      pluginId: 'chat',
      name: '聊天概览',
      description: '显示频道和消息统计',
      icon: Icons.chat_bubble_outline,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '通讯',
      builder: (context, config) => _buildOverviewWidget(context),
    ));
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.chat_bubble,
        size: 48,
        color: Colors.indigoAccent,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = ChatLocalizations.of(context);
      final channels = plugin.channelService.channels;
      final totalMessages = plugin.channelService.getTotalMessageCount();
      final todayMessages = plugin.channelService.getTodayMessageCount();

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
                    color: Colors.indigoAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    size: 24,
                    color: Colors.indigoAccent,
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
                  // 第一行：频道数和总消息数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.channelCount,
                        value: '${channels.length}',
                        theme: theme,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: theme.dividerColor,
                      ),
                      _StatItem(
                        label: l10n.totalMessages,
                        value: '$totalMessages',
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行：今日消息数
                  _StatItem(
                    label: l10n.todayMessages,
                    value: '$todayMessages',
                    theme: theme,
                    highlight: todayMessages > 0,
                    color: Colors.indigoAccent,
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
