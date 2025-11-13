import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';
import 'home_card.dart';

/// 主页网格布局组件
///
/// 使用 StaggeredGridView 支持不同尺寸的卡片
class HomeGrid extends StatelessWidget {
  final List<HomeItem> items;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(HomeItem item)? onItemTap;
  final Function(HomeItem item)? onItemLongPress;
  final int crossAxisCount;

  const HomeGrid({
    super.key,
    required this.items,
    this.onReorder,
    this.onItemTap,
    this.onItemLongPress,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: StaggeredGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: items.map((item) => _buildGridTile(context, item)).toList(),
      ),
    );
  }

  /// 构建单个网格瓦片
  Widget _buildGridTile(BuildContext context, HomeItem item) {
    // 获取卡片尺寸
    int crossAxisCellCount = 1;
    int mainAxisCellCount = 1;

    if (item is HomeWidgetItem) {
      crossAxisCellCount = item.size.width;
      mainAxisCellCount = item.size.height;
    } else if (item is HomeFolderItem) {
      // 文件夹固定为 1x1
      crossAxisCellCount = 1;
      mainAxisCellCount = 1;
    }

    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: mainAxisCellCount,
      child: HomeCard(
        key: ValueKey(item.id),
        item: item,
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        onLongPress: onItemLongPress != null ? () => onItemLongPress!(item) : null,
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有小组件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角的 + 按钮添加',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 可重新排序的主页网格（支持拖拽）
///
/// 暂时简化，后续可以使用 reorderable_grid_view 包
class ReorderableHomeGrid extends StatefulWidget {
  final List<HomeItem> items;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(HomeItem item)? onItemTap;
  final Function(HomeItem item)? onItemLongPress;
  final int crossAxisCount;

  const ReorderableHomeGrid({
    super.key,
    required this.items,
    required this.onReorder,
    this.onItemTap,
    this.onItemLongPress,
    this.crossAxisCount = 2,
  });

  @override
  State<ReorderableHomeGrid> createState() => _ReorderableHomeGridState();
}

class _ReorderableHomeGridState extends State<ReorderableHomeGrid> {
  @override
  Widget build(BuildContext context) {
    // 暂时使用普通的 HomeGrid，后续可以添加拖拽功能
    return HomeGrid(
      items: widget.items,
      onReorder: widget.onReorder,
      onItemTap: widget.onItemTap,
      onItemLongPress: widget.onItemLongPress,
      crossAxisCount: widget.crossAxisCount,
    );
  }
}
