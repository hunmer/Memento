import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';
import '../managers/home_widget_registry.dart';
import 'home_card.dart';

/// 主页网格布局组件
///
/// 支持长按拖拽排序和批量选择
class HomeGrid extends StatefulWidget {
  final List<HomeItem> items;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String itemId, String folderId)? onAddToFolder;
  final Function(HomeItem item)? onItemTap;
  final Function(HomeItem item)? onItemLongPress;
  final int crossAxisCount;
  final bool isEditMode;
  final bool isBatchMode;
  final Set<String> selectedItemIds;
  final Alignment alignment;

  const HomeGrid({
    super.key,
    required this.items,
    this.onReorder,
    this.onAddToFolder,
    this.onItemTap,
    this.onItemLongPress,
    this.crossAxisCount = 2,
    this.isEditMode = false,
    this.isBatchMode = false,
    this.selectedItemIds = const {},
    this.alignment = Alignment.topCenter,
  });

  @override
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> {
  int? _draggingIndex;
  int? _hoveringIndex;

  /// 处理添加到文件夹的操作
  void _handleAddToFolder(String itemId, String folderId) {
    if (widget.onAddToFolder != null) {
      widget.onAddToFolder!(itemId, folderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }

    final gridWidget = Padding(
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

    // 根据对齐方式选择不同的布局
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.alignment == Alignment.center) {
          // 居中模式：内容在可用空间中垂直居中
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: gridWidget,
              ),
            ),
          );
        }

        // 顶部模式：内容从顶部开始
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: gridWidget,
            ),
          ),
        );
      },
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

    // 如果不是编辑模式，返回普通卡片（包括批量选择模式）
    if (!widget.isEditMode) {
      final isSelected = widget.isBatchMode && widget.selectedItemIds.contains(item.id);

      return StaggeredGridTile.count(
        crossAxisCellCount: crossAxisCellCount,
        mainAxisCellCount: mainAxisCellCount,
        child: HomeCard(
          key: ValueKey(item.id),
          item: item,
          isSelected: isSelected,
          isBatchMode: widget.isBatchMode,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
          onLongPress: widget.onItemLongPress != null ? () => widget.onItemLongPress!(item) : null,
        ),
      );
    }

    // 编辑模式下启用拖拽
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
        onAcceptWithDetails: (details) async {
          final oldIndex = details.data;
          final newIndex = index;
          final targetItem = widget.items[newIndex];

          setState(() {
            _hoveringIndex = null;
            _draggingIndex = null;
          });

          if (oldIndex == newIndex) return;

          // 如果目标是文件夹，显示对话框
          if (targetItem is HomeFolderItem && widget.onReorder != null) {
            final draggedItem = widget.items[oldIndex];
            final result = await _showDragToFolderDialog(
              context,
              draggedItem,
              targetItem,
            );

            if (result == _DragToFolderAction.replace) {
              // 替换位置：执行正常的重排序
              widget.onReorder!(oldIndex, newIndex);
            } else if (result == _DragToFolderAction.addToFolder) {
              // 添加到文件夹：需要通过回调通知父组件
              // 这里我们通过特殊的索引值来标记这个操作
              // 父组件需要处理这种情况
              _handleAddToFolder(draggedItem.id, targetItem.id);
            }
          } else if (widget.onReorder != null) {
            // 普通重排序
            widget.onReorder!(oldIndex, newIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          // 创建拖拽手柄（不包裹在 Draggable 中，只是视觉提示）
          final dragHandleWidget = Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.drag_indicator,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          );

          // 整个卡片可拖拽
          return Draggable<int>(
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HomeCard(
                  key: ValueKey('${item.id}_dragging'),
                  item: item,
                  isEditMode: true,
                  dragHandle: dragHandleWidget,
                ),
              ),
            ),
            onDragStarted: () {
              setState(() {
                _draggingIndex = index;
              });
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
                isEditMode: true,
                onTap: null,
                onLongPress: null,
                dragHandle: dragHandleWidget,
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

/// 拖拽到文件夹的操作枚举
enum _DragToFolderAction {
  replace,      // 替换位置
  addToFolder,  // 添加到文件夹
  cancel,       // 取消
}

/// 显示拖拽到文件夹的对话框
Future<_DragToFolderAction?> _showDragToFolderDialog(
  BuildContext context,
  HomeItem draggedItem,
  HomeFolderItem targetFolder,
) async {
  // 获取拖拽项的名称
  String itemName;
  if (draggedItem is HomeWidgetItem) {
    final registry = HomeWidgetRegistry();
    itemName = registry.getWidget(draggedItem.widgetId)?.name ?? '组件';
  } else if (draggedItem is HomeFolderItem) {
    itemName = draggedItem.name;
  } else {
    itemName = '项目';
  }

  return showDialog<_DragToFolderAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('拖拽到文件夹'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将 "$itemName" 拖拽到文件夹 "${targetFolder.name}"'),
          const SizedBox(height: 16),
          const Text('请选择操作：'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.cancel),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.replace),
          child: const Text('替换位置'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.addToFolder),
          child: const Text('添加到文件夹'),
        ),
      ],
    ),
  );
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
  final Alignment alignment;

  const ReorderableHomeGrid({
    super.key,
    required this.items,
    required this.onReorder,
    this.onItemTap,
    this.onItemLongPress,
    this.crossAxisCount = 2,
    this.alignment = Alignment.topCenter,
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
      alignment: widget.alignment,
    );
  }
}
