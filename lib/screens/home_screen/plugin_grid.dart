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

  List<PluginBase> _optimizePluginOrder(
    List<PluginBase> plugins,
    int crossAxisCount,
  ) {
    // 创建网格占用情况的二维数组，增加行数以适应更高的卡片
    final maxRows = (plugins.length * 4) ~/ crossAxisCount + 1;
    final gridOccupancy = List.generate(
      maxRows,
      (_) => List.filled(crossAxisCount, false),
    );

    final result = <PluginBase>[];
    final remainingPlugins = List<PluginBase>.from(plugins);

    // 用于检查和填充空隙的辅助函数
    void fillGaps(int upToRow) {
      // 从上到下，从左到右检查空隙
      for (int row = 0; row <= upToRow; row++) {
        for (int col = 0; col < crossAxisCount; col++) {
          if (!gridOccupancy[row][col]) {
            // 找出标准大小（1x1）的卡片
            final standardCardIndex = remainingPlugins.indexWhere((plugin) {
              final size = _getCardSize(plugin.id);
              return size.width == 1 && size.height == 1;
            });

            if (standardCardIndex != -1) {
              // 找到标准卡片，填充空隙
              final plugin = remainingPlugins.removeAt(standardCardIndex);
              gridOccupancy[row][col] = true;
              result.add(plugin);
            }
          }
        }
      }
    }

    // 按照卡片大小排序，优先放置大卡片
    remainingPlugins.sort((a, b) {
      final sizeA = _getCardSize(a.id);
      final sizeB = _getCardSize(b.id);
      final areaA = sizeA.width * sizeA.height;
      final areaB = sizeB.width * sizeB.height;
      return areaB.compareTo(areaA); // 大卡片优先
    });

    // 逐个放置卡片
    while (remainingPlugins.isNotEmpty) {
      final plugin = remainingPlugins[0];
      final size = _getCardSize(plugin.id);
      final width = size.width.clamp(1, crossAxisCount);
      final height = size.height.clamp(1, 4);

      bool placed = false;
      int placedRow = 0;

      // 尝试放置当前卡片
      for (int row = 0; row < maxRows - height + 1 && !placed; row++) {
        for (int col = 0; col < crossAxisCount - width + 1 && !placed; col++) {
          bool canPlace = true;
          // 检查区域是否可用
          for (int h = 0; h < height && canPlace; h++) {
            for (int w = 0; w < width && canPlace; w++) {
              if (gridOccupancy[row + h][col + w]) {
                canPlace = false;
              }
            }
          }

          if (canPlace) {
            // 标记区域为已占用
            for (int h = 0; h < height; h++) {
              for (int w = 0; w < width; w++) {
                gridOccupancy[row + h][col + w] = true;
              }
            }
            result.add(remainingPlugins.removeAt(0));
            placed = true;
            placedRow = row + height - 1;
          }
        }
      }

      if (!placed) {
        // 如果无法按原始大小放置，将其作为1x1处理
        final plugin = remainingPlugins.removeAt(0);
        bool standardPlaced = false;
        for (int row = 0; row < maxRows && !standardPlaced; row++) {
          for (int col = 0; col < crossAxisCount && !standardPlaced; col++) {
            if (!gridOccupancy[row][col]) {
              gridOccupancy[row][col] = true;
              result.add(plugin);
              standardPlaced = true;
              placedRow = row;
            }
          }
        }
      }

      // 在每次放置卡片后立即填充空隙
      fillGaps(placedRow);
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

  Widget _buildReorderableGrid(
    List<PluginBase> sortedPlugins,
    int crossAxisCount,
    BuildContext context,
  ) {
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        mainAxisExtent: 120, // 进一步减少基础卡片高度
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

  Widget _buildStaggeredGrid(
    List<PluginBase> sortedPlugins,
    int crossAxisCount,
    BuildContext context,
  ) {
    // 对插件进行排序，优先放置自定义大小卡片，然后是标准卡片
    final optimizedPlugins = _optimizePluginOrder(
      sortedPlugins,
      crossAxisCount,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: StaggeredGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children:
              optimizedPlugins.map((plugin) {
                final cardSize = _getCardSize(plugin.id);
                // 确保宽度不超过可用列数
                final crossAxisCellCount = cardSize.width.clamp(
                  1,
                  crossAxisCount,
                );
                // 确保高度在1-4之间
                final mainAxisCellCount = cardSize.height.clamp(1, 4);

                return StaggeredGridTile.count(
                  crossAxisCellCount: crossAxisCellCount,
                  mainAxisCellCount: mainAxisCellCount,
                  child: PluginCard(
                    plugin: plugin,
                    isReorderMode: isReorderMode,
                    cardSize: cardSize,
                    onShowSizeMenu:
                        (context) => onShowCardSizeMenu(context, plugin),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
