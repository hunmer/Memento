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

  const PluginGrid({
    super.key,
    required this.plugins,
    required this.isReorderMode,
    required this.cardSizes,
    required this.pluginOrder,
    required this.onReorder,
    required this.onShowCardSizeMenu,
  });

  CardSize _getCardSize(String pluginId) {
    return cardSizes[pluginId] ?? const CardSize(width: 1, height: 1);
  }

  List<PluginBase> _optimizePluginOrder(List<PluginBase> plugins, int crossAxisCount) {
    // 创建网格占用情况的二维数组
    final gridOccupancy = List.generate(
      (plugins.length * 4) ~/ crossAxisCount + 1, // 增加行数以适应更高的卡片
      (_) => List.filled(crossAxisCount, false),
    );

    final result = <PluginBase>[];
    
    // 先处理宽度或高度大于1的卡片
    final customSizeCards = <PluginBase>[];
    final standardCards = <PluginBase>[];
    
    for (final plugin in plugins) {
      final size = _getCardSize(plugin.id);
      if (size.width > 1 || size.height > 1) {
        customSizeCards.add(plugin);
      } else {
        standardCards.add(plugin);
      }
    }
    
    // 放置自定义大小的卡片
    for (final plugin in customSizeCards) {
      final size = _getCardSize(plugin.id);
      final width = size.width.clamp(1, crossAxisCount);
      final height = size.height.clamp(1, 4);
      
      bool placed = false;
      for (int row = 0; row < gridOccupancy.length - height + 1 && !placed; row++) {
        for (int col = 0; col < crossAxisCount - width + 1 && !placed; col++) {
          // 检查这个区域是否可用
          bool canPlace = true;
          for (int h = 0; h < height && canPlace; h++) {
            for (int w = 0; w < width && canPlace; w++) {
              if (gridOccupancy[row + h][col + w]) {
                canPlace = false;
              }
            }
          }
          
          if (canPlace) {
            // 标记这个区域为已占用
            for (int h = 0; h < height; h++) {
              for (int w = 0; w < width; w++) {
                gridOccupancy[row + h][col + w] = true;
              }
            }
            result.add(plugin);
            placed = true;
          }
        }
      }
      
      // 如果无法放置，则作为标准卡片处理
      if (!placed) {
        standardCards.add(plugin);
      }
    }
    
    // 放置标准大小的卡片
    for (final plugin in standardCards) {
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
    // 对插件进行排序，优先放置自定义大小卡片，然后是标准卡片
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
            // 确保宽度不超过可用列数
            final crossAxisCellCount = cardSize.width.clamp(1, crossAxisCount);
            // 确保高度在1-4之间
            final mainAxisCellCount = cardSize.height.clamp(1, 4);
            
            return StaggeredGridTile.count(
              crossAxisCellCount: crossAxisCellCount,
              mainAxisCellCount: mainAxisCellCount,
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