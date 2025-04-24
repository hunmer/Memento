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

  List<PluginBase> _optimizePluginOrder(List<PluginBase> plugins, int crossAxisCount) {
    // 将插件按卡片大小分类
    final wideCards = <PluginBase>[];
    final tallCards = <PluginBase>[];
    final smallCards = <PluginBase>[];

    for (final plugin in plugins) {
      final size = _getCardSize(plugin.id);
      switch (size) {
        case CardSize.wide:
          wideCards.add(plugin);
          break;
        case CardSize.tall:
          tallCards.add(plugin);
          break;
        case CardSize.small:
          smallCards.add(plugin);
          break;
      }
    }

    // 创建网格占用情况的二维数组
    final gridOccupancy = List.generate(
      (plugins.length * 2) ~/ crossAxisCount + 1,
      (_) => List.filled(crossAxisCount, false),
    );

    final result = <PluginBase>[];
    
    // 优先放置宽卡片（占用2列）
    for (final plugin in wideCards) {
      for (int row = 0; row < gridOccupancy.length - 1; row++) {
        for (int col = 0; col < crossAxisCount - 1; col++) {
          if (!gridOccupancy[row][col] && !gridOccupancy[row][col + 1]) {
            gridOccupancy[row][col] = true;
            gridOccupancy[row][col + 1] = true;
            result.add(plugin);
            break;
          }
        }
        if (result.length == wideCards.length) break;
      }
    }

    // 放置高卡片（占用2行或更多）
    for (final plugin in tallCards) {
      final height = tallCardHeights[plugin.id] ?? 2;
      for (int col = 0; col < crossAxisCount; col++) {
        for (int row = 0; row < gridOccupancy.length - height; row++) {
          bool canPlace = true;
          for (int h = 0; h < height; h++) {
            if (gridOccupancy[row + h][col]) {
              canPlace = false;
              break;
            }
          }
          if (canPlace) {
            for (int h = 0; h < height; h++) {
              gridOccupancy[row + h][col] = true;
            }
            result.add(plugin);
            break;
          }
        }
        if (result.length == wideCards.length + tallCards.length) break;
      }
    }

    // 最后填充小卡片
    for (final plugin in smallCards) {
      bool placed = false;
      for (int row = 0; row < gridOccupancy.length && !placed; row++) {
        for (int col = 0; col < crossAxisCount && !placed; col++) {
          if (!gridOccupancy[row][col]) {
            gridOccupancy[row][col] = true;
            result.add(plugin);
            placed = true;
          }
        }
      }
    }

    return result;
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
          return _buildStaggeredGrid(sortedPlugins, crossAxisCount, context);
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

  Widget _buildStaggeredGrid(List<PluginBase> sortedPlugins, int crossAxisCount, BuildContext context) {
    // 对插件进行排序，优先放置大卡片，然后是小卡片
    final optimizedPlugins = _optimizePluginOrder(sortedPlugins, crossAxisCount);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: StaggeredGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: optimizedPlugins.map((plugin) {
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