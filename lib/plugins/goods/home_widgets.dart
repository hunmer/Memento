import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'goods_plugin.dart';
import 'l10n/goods_localizations.dart';

/// 物品管理插件的主页小组件注册
class GoodsHomeWidgets {
  /// 注册所有物品管理插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'goods_icon',
      pluginId: 'goods',
      name: '物品',
      description: '快速打开物品管理',
      icon: Icons.inventory_2,
      color: const Color.fromARGB(255, 207, 77, 116),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'goods_overview',
      pluginId: 'goods',
      name: '物品概览',
      description: '显示物品数量、价值和使用情况',
      icon: Icons.dashboard,
      color: const Color.fromARGB(255, 207, 77, 116),
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
        Icons.inventory_2,
        size: 48,
        color: const Color.fromARGB(255, 207, 77, 116),
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = GoodsLocalizations.of(context);
      final totalItems = plugin.getTotalItemsCount();
      final totalValue = plugin.getTotalItemsValue();
      final unusedItems = plugin.getUnusedItemsCount();

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
                    color: const Color.fromARGB(255, 207, 77, 116).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 24,
                    color: Color.fromARGB(255, 207, 77, 116),
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
                  // 第一行：物品总数和总价值
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.totalQuantity,
                        value: '$totalItems',
                        theme: theme,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: theme.dividerColor,
                      ),
                      _StatItem(
                        label: l10n.totalValue,
                        value: '¥${totalValue.toStringAsFixed(0)}',
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行：未使用物品数
                  _StatItem(
                    label: l10n.oneMonthUnused,
                    value: '$unusedItems',
                    theme: theme,
                    highlight: unusedItems > 0,
                    color: theme.colorScheme.error,
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
