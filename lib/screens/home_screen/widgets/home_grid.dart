import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';
import 'home_card.dart';

/// 主页网格布局组件
///
/// 支持长按拖拽排序
class HomeGrid extends StatefulWidget {
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
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> {
  int? _draggingIndex;
  int? _hoveringIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: StaggeredGrid.count(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: List.generate(widget.items.length, (index) {
          return _buildDraggableTile(context, widget.items[index], index);
        }),
      ),
    );
  }

  /// 构建可拖拽的网格瓦片
  Widget _buildDraggableTile(BuildContext context, HomeItem item, int index) {
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

    final isBeingDragged = _draggingIndex == index;
    final isHovering = _hoveringIndex == index;

    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: mainAxisCellCount,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          setState(() {
            _hoveringIndex = index;
          });
          return details.data != index;
        },
        onLeave: (_) {
          setState(() {
            _hoveringIndex = null;
          });
        },
        onAcceptWithDetails: (details) {
          final oldIndex = details.data;
          final newIndex = index;

          setState(() {
            _hoveringIndex = null;
            _draggingIndex = null;
          });

          if (oldIndex != newIndex && widget.onReorder != null) {
            widget.onReorder!(oldIndex, newIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return LongPressDraggable<int>(
            data: index,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: 0.8,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.drag_indicator,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: HomeCard(
                key: ValueKey(item.id),
                item: item,
              ),
            ),
            onDragStarted: () {
              setState(() {
                _draggingIndex = index;
              });
              // 提供触觉反馈
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (_) {
              setState(() {
                _draggingIndex = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isHovering
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
              ),
              child: HomeCard(
                key: ValueKey(item.id),
                item: item,
                isSelected: isBeingDragged || isHovering,
                onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
                onLongPress: widget.onItemLongPress != null ? () => widget.onItemLongPress!(item) : null,
              ),
            ),
          );
        },
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
