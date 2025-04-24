import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../core/plugin_base.dart';
import 'card_size.dart';
import 'plugin_card.dart';

class PluginGrid extends StatelessWidget {
  final List<PluginBase> plugins;
  final bool isReorderMode;
  final Map<String, CardSize> cardSizes;
  final List<String> pluginOrder;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(BuildContext, PluginBase) onShowCardSizeMenu;
  final Map<String, int> tallCardHeights;

  const PluginGrid({
    super.key,
    required this.plugins,
    required this.isReorderMode,
    required this.cardSizes,
    required this.pluginOrder,
    required this.onReorder,
    required this.onShowCardSizeMenu,
    required this.tallCardHeights,
  });

  CardSize _getCardSize(String pluginId) {
    return cardSizes[pluginId] ?? CardSize.small;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度动态计算列数
        int crossAxisCount = (constraints.maxWidth / 300).floor();
        // 确保至少有2列，最多4列
        crossAxisCount = crossAxisCount.clamp(2, 4);

        final sortedPlugins = List<PluginBase>.from(plugins);

        if (isReorderMode) {
          return _buildReorderableGrid(sortedPlugins, crossAxisCount, context);
        } else {
          return _buildQuiltedGrid(sortedPlugins, crossAxisCount, context);
        }
      },
    );
  }

  Widget _buildReorderableGrid(List<PluginBase> sortedPlugins, int crossAxisCount, BuildContext context) {
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        mainAxisExtent: 180, // 基础卡片高度
      ),
      itemCount: sortedPlugins.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final plugin = sortedPlugins[index];
        return Card(
          key: ValueKey(plugin.id),
          elevation: 2.0,
          margin: EdgeInsets.zero,
          child: PluginCard(
            plugin: plugin,
            isReorderMode: isReorderMode,
            cardSize: _getCardSize(plugin.id),
            onShowSizeMenu: (context) => onShowCardSizeMenu(context, plugin),
          ),
        );
      },
    );
  }

  Widget _buildQuiltedGrid(List<PluginBase> sortedPlugins, int crossAxisCount, BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: StaggeredGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: sortedPlugins.map((plugin) {
        final cardSize = _getCardSize(plugin.id);
        int mainAxisCount = 1;
        if (cardSize == CardSize.tall) {
          mainAxisCount = tallCardHeights[plugin.id] ?? 2;  // 默认高度为2
        }
        
        return StaggeredGridTile.count(
          crossAxisCellCount: cardSize == CardSize.wide ? 2 : 1,
          mainAxisCellCount: cardSize == CardSize.tall ? mainAxisCount : 1,
          child: PluginCard(
            plugin: plugin,
            isReorderMode: isReorderMode,
            cardSize: cardSize,
            onShowSizeMenu: (context) => onShowCardSizeMenu(context, plugin),
          ),
        );
      }).toList(),
        ),
      ),
    );
  }
}