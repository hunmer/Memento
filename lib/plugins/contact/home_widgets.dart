import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'contact_plugin.dart';
import 'l10n/contact_localizations.dart';

/// 联系人插件的主页小组件注册
class ContactHomeWidgets {
  /// 注册所有联系人插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'contact_icon',
      pluginId: 'contact',
      name: '联系人',
      description: '快速打开联系人管理',
      icon: Icons.contacts,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'contact_overview',
      pluginId: 'contact',
      name: '联系人概览',
      description: '显示联系人总数和最近联系统计',
      icon: Icons.people,
      color: Colors.deepPurple,
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
        Icons.contacts,
        size: 48,
        color: Colors.deepPurple,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = ContactLocalizations.of(context);

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
                    color: Colors.deepPurple.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contacts,
                    size: 24,
                    color: Colors.deepPurple,
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
                future: _getCardStats(plugin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final stats = snapshot.data ?? {
                    'totalContacts': 0,
                    'recentContacts': 0,
                  };

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 第一行：总联系人和最近联系人
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.totalContacts,
                            value: '${stats['totalContacts']}',
                            theme: theme,
                            highlight: stats['totalContacts']! > 0,
                            color: Colors.deepPurple,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.dividerColor,
                          ),
                          _StatItem(
                            label: l10n.recentContacts,
                            value: '${stats['recentContacts']}',
                            theme: theme,
                            highlight: stats['recentContacts']! > 0,
                            color: Colors.green,
                          ),
                        ],
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

  /// 获取卡片统计数据
  static Future<Map<String, int>> _getCardStats(ContactPlugin plugin) async {
    try {
      final controller = plugin.controller;
      final contacts = await controller.getAllContacts();
      final recentContacts = await controller.getRecentlyContactedCount();

      return {
        'totalContacts': contacts.length,
        'recentContacts': recentContacts,
      };
    } catch (e) {
      return {
        'totalContacts': 0,
        'recentContacts': 0,
      };
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
