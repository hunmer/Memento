
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/models/home_stack_item.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'home_card.dart';

/// 主页网格布局组件
///
/// 支持长按拖拽排序和批量选择
class HomeGrid extends StatefulWidget {
  final List<HomeItem> items;
  final String? layoutId;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String itemId, String folderId)? onAddToFolder;
  final Function(HomeItem item)? onItemTap;
  final Function(HomeItem item)? onItemLongPress;
  final int crossAxisCount;
  final bool isEditMode;
  final bool isBatchMode;
  final Set<String> selectedItemIds;
  final Alignment alignment;
  final void Function(Map<String, String>)? onQuickCreateLayout;
  /// 是否显示骨架屏（用于占位加载）
  final bool showSkeleton;
  final Future<bool> Function(BuildContext context, HomeItem target, HomeItem dragged)? onMergeIntoStack;
  final void Function(String layoutId, HomeItem item)? onDragStarted;
  final VoidCallback? onDragEnded;
  final Future<bool> Function(String draggedItemId, String targetLayoutId, int targetIndex)?
      onCrossLayoutDrop;

  const HomeGrid({
    super.key,
    required this.items,
    this.layoutId,
    this.onReorder,
    this.onAddToFolder,
    this.onItemTap,
    this.onItemLongPress,
    this.crossAxisCount = 2,
    this.isEditMode = false,
    this.isBatchMode = false,
    this.selectedItemIds = const {},
    this.alignment = Alignment.topCenter,
    this.onQuickCreateLayout,
    this.showSkeleton = false,
    this.onMergeIntoStack,
    this.onDragStarted,
    this.onDragEnded,
    this.onCrossLayoutDrop,
  });

  @override
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> {
  int? _draggingIndex;
  int? _hoveringIndex;
  String? _draggingItemId;
  _DropRegion? _hoveredDropZone;
  Timer? _previewTimer;
  final List<String> _displayOrder = [];
  String? _previewDraggingId;
  int? _pendingTargetIndex;

  // 用于存储每个卡片的 GlobalKey，以准确获取其位置
  final Map<int, GlobalKey> _cardKeys = {};

  // 存储真正的指针全局位置
  Offset? _lastPointerPosition;

  @override
  void initState() {
    super.initState();
    _syncDisplayOrder();
  }

  @override
  void didUpdateWidget(covariant HomeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameItems(oldWidget.items, widget.items)) {
      _syncDisplayOrder();
    }
  }

  void _syncDisplayOrder() {
    _displayOrder
      ..clear()
      ..addAll(widget.items.map((item) => item.id));
  }

  bool _hasSameItems(List<HomeItem> oldItems, List<HomeItem> newItems) {
    if (oldItems.length != newItems.length) return false;
    for (var i = 0; i < oldItems.length; i++) {
      if (oldItems[i].id != newItems[i].id) return false;
    }
    return true;
  }

  void _resetPreviewOrder() {
    _previewDraggingId = null;
    _pendingTargetIndex = null;
    _hoveredDropZone = null;
    _displayOrder
      ..clear()
      ..addAll(widget.items.map((item) => item.id));
  }

  List<HomeItem> _buildOrderedItems() {
    if (_displayOrder.length != widget.items.length) {
      _syncDisplayOrder();
    }
    final map = {for (final item in widget.items) item.id: item};
    final ordered = <HomeItem>[];
    for (final id in _displayOrder) {
      final item = map[id];
      if (item != null) {
        ordered.add(item);
      }
    }
    if (ordered.length != widget.items.length) {
      return widget.items;
    }
    return ordered;
  }

  /// 处理添加到文件夹的操作
  void _handleAddToFolder(String itemId, String folderId) {
    if (widget.onAddToFolder != null) {
      widget.onAddToFolder!(itemId, folderId);
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderedItems = _buildOrderedItems();
    if (orderedItems.isEmpty) {
      return _buildEmptyState(context);
    }

    final gridWidget = Padding(
      padding: const EdgeInsets.all(8),
      child: StaggeredGrid.count(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: List.generate(orderedItems.length, (index) {
          return _buildDraggableTile(context, orderedItems[index], index);
        }),
      ),
    );

    // 根据对齐方式选择不同的布局，并用 Listener 包裹以捕获真正的指针位置
    return Listener(
      onPointerMove: (event) {
        _lastPointerPosition = event.position;
      },
      onPointerHover: (event) {
        _lastPointerPosition = event.position;
      },
      child: LayoutBuilder(
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
      ),
    );
  }

  /// 构建可拖拽的网格瓦片
  Widget _buildDraggableTile(BuildContext context, HomeItem item, int index) {
    int crossAxisCellCount = 1;
    int mainAxisCellCount = 1;

    if (item is HomeWidgetItem) {
      if (item.size == HomeWidgetSize.custom) {
        crossAxisCellCount = item.config['customWidth'] as int? ?? 2;
        mainAxisCellCount = item.config['customHeight'] as int? ?? 2;
      } else {
        crossAxisCellCount = item.size.width;
        mainAxisCellCount = item.size.height;
      }
    } else if (item is HomeStackItem) {
      if (item.size == HomeWidgetSize.custom) {
        if (item.children.isNotEmpty) {
          crossAxisCellCount = item.children.first.config['customWidth'] as int? ?? 2;
          mainAxisCellCount = item.children.first.config['customHeight'] as int? ?? 2;
        } else {
          crossAxisCellCount = 2;
          mainAxisCellCount = 2;
        }
      } else {
        crossAxisCellCount = item.size.width;
        mainAxisCellCount = item.size.height;
      }
    } else if (item is HomeFolderItem) {
      crossAxisCellCount = 1;
      mainAxisCellCount = 1;
    }

    if (widget.showSkeleton) {
      return StaggeredGridTile.count(
        crossAxisCellCount: crossAxisCellCount,
        mainAxisCellCount: mainAxisCellCount,
        child: _buildSkeletonCard(),
      );
    }

    final isBeingDragged = _draggingIndex == index;
    final isHoveringCenter = _hoveringIndex == index;
    final pluginState = _resolvePluginState(context, item);

    if (!widget.isEditMode) {
      final isSelected = widget.isBatchMode && widget.selectedItemIds.contains(item.id);
      final bool shouldInterceptTap = pluginState.isPluginItem && pluginState.isDisabled;

      Widget card = HomeCard(
        key: ValueKey(item.id),
        item: item,
        isSelected: isSelected,
        isBatchMode: widget.isBatchMode,
        onTap: shouldInterceptTap
            ? () => _showPluginDisabledToast(context, pluginState)
            : widget.onItemTap != null
                ? () => widget.onItemTap!(item)
                : null,
        onLongPress: widget.onItemLongPress != null ? () => widget.onItemLongPress!(item) : null,
      );

      card = _wrapWithDisabledOverlay(context, card, pluginState, isInEditMode: false);

      return StaggeredGridTile.count(
        crossAxisCellCount: crossAxisCellCount,
        mainAxisCellCount: mainAxisCellCount,
        child: card,
      );
    }

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

    final draggableCard = Draggable<String>(
      data: item.id,
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
          child: _wrapWithDisabledOverlay(
            context,
            HomeCard(
              key: ValueKey('${item.id}_dragging'),
              item: item,
              isEditMode: true,
              dragHandle: dragHandleWidget,
            ),
            pluginState,
            isInEditMode: true,
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _draggingIndex = index;
          _draggingItemId = item.id;
        });
        _previewTimer?.cancel();
        if (widget.layoutId != null && widget.onDragStarted != null) {
          widget.onDragStarted!(widget.layoutId!, item);
        }
        HapticFeedback.mediumImpact();
      },
      onDragEnd: (_) {
        setState(() {
          _draggingIndex = null;
          _draggingItemId = null;
          _hoveredDropZone = null;
          _resetPreviewOrder();
        });
        _previewTimer?.cancel();
        widget.onDragEnded?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isHoveringCenter
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: _wrapWithDisabledOverlay(
          context,
          HomeCard(
            key: ValueKey(item.id),
            item: item,
            isSelected: isBeingDragged || isHoveringCenter,
            isEditMode: true,
            dragHandle: dragHandleWidget,
          ),
          pluginState,
          isInEditMode: true,
        ),
      ),
    );

    final centerTarget = DragTarget<String>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        setState(() {
          _hoveringIndex = index;
        });
        return details.data != item.id;
      },
      onLeave: (_) {
        setState(() {
          _hoveringIndex = null;
        });
      },
      onAcceptWithDetails: (details) async {
        await _handleCenterDrop(context, index, details);
      },
      builder: (context, candidateData, rejectedData) => draggableCard,
    );

    // 获取或创建该索引的 GlobalKey
    _cardKeys[index] ??= GlobalKey();

    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: mainAxisCellCount,
      child: Stack(
        key: _cardKeys[index],
        clipBehavior: Clip.none,
        children: [
          centerTarget,
          if (widget.isEditMode) _buildDirectionalOverlay(context, index),
        ],
      ),
    );
  }
  Widget _buildDirectionalOverlay(BuildContext context, int index) {
    return Positioned.fill(
      child: Builder(
        builder: (overlayContext) {
          return DragTarget<String>(
            hitTestBehavior: HitTestBehavior.translucent,
            onWillAcceptWithDetails: (details) => _handleDirectionalHover(overlayContext, index, details),
            onMove: (details) => _handleDirectionalHover(overlayContext, index, details),
            onLeave: (_) => _handleDirectionalLeave(index),
            onAcceptWithDetails: (_) {},
            builder: (context, candidateData, rejectedData) {
              final zone = _hoveredDropZone;
              final bool isActive = zone != null && zone.index == index;
              return IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: isActive ? 0.45 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: _buildDropIndicator(context, zone?.direction),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDropIndicator(BuildContext context, _DropDirection? direction) {
    final theme = Theme.of(context);

    // 中心区域：显示合并/堆叠指示器
    if (direction == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.layers,
            size: 48,
            color: theme.primaryColor.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // 边缘区域：显示方向指示器
    final bool isHorizontal = direction == _DropDirection.top || direction == _DropDirection.bottom;
    return Align(
      alignment: _alignmentForDirection(direction),
      child: FractionallySizedBox(
        widthFactor: isHorizontal ? 1 : 0.35,
        heightFactor: isHorizontal ? 0.35 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  bool _handleDirectionalHover(
    BuildContext context,
    int index,
    DragTargetDetails<String> details,
  ) {
    final draggedId = details.data;
    final displayItems = _buildOrderedItems();
    if (draggedId == null || index < 0 || index >= displayItems.length) {
      return false;
    }
    if (draggedId == displayItems[index].id) {
      return false;
    }

    // 使用 GlobalKey 获取正确的 RenderBox
    final cardKey = _cardKeys[index];
    final renderBox = cardKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      debugPrint('[HomeGrid] ❌ renderBox is null or has no size for index $index');
      return false;
    }

    // 使用真正的指针位置，而不是 details.offset（后者是 feedback widget 的位置）
    final globalPosition = _lastPointerPosition ?? details.offset;
    final localOffset = renderBox.globalToLocal(globalPosition);

    // 调试输出
    debugPrint('[HomeGrid] ────────────────────────────────────────');
    debugPrint('[HomeGrid] 📍 Index: $index');
    debugPrint('[HomeGrid] 🌍 Real pointer position: $globalPosition');
    debugPrint('[HomeGrid] 📐 RenderBox size: ${renderBox.size}');
    debugPrint('[HomeGrid] 🎯 Local offset: $localOffset');
    debugPrint('[HomeGrid] 📊 Normalized: x=${(localOffset.dx / renderBox.size.width).toStringAsFixed(2)}, y=${(localOffset.dy / renderBox.size.height).toStringAsFixed(2)}');

    final direction = _resolveDirectionFromOffset(localOffset, renderBox.size);
    debugPrint('[HomeGrid] 🧭 Direction: $direction');

    // direction 为 null 表示中心区域（合并/堆叠操作）
    final zone = _DropRegion(index, direction);
    if (_hoveredDropZone == zone) {
      return true;
    }

    _activateDropZone(zone);
    return true;
  }

  void _handleDirectionalLeave(int index) {
    if (_hoveredDropZone?.index != index) {
      return;
    }
    _clearHoveredZone();
  }

  _DropDirection? _resolveDirectionFromOffset(Offset local, Size size) {
    final double width = size.width;
    final double height = size.height;
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      debugPrint('[HomeGrid] ⚠️ Invalid size: $size');
      return null;
    }

    // 使用九宫格布局判断，边缘区域占35%，中间区域占30%
    final double edgeRatio = 0.35;
    final double clampedX = local.dx.clamp(0.0, width);
    final double clampedY = local.dy.clamp(0.0, height);

    // 计算归一化位置 (0-1)
    final double normalizedX = clampedX / width;
    final double normalizedY = clampedY / height;

    // 判断水平位置：0=左, 1=中, 2=右
    final int hZone;
    final String hReason;
    if (normalizedX < edgeRatio) {
      hZone = 0; // 左
      hReason = 'x=${normalizedX.toStringAsFixed(2)} < ${edgeRatio}';
    } else if (normalizedX > (1 - edgeRatio)) {
      hZone = 2; // 右
      hReason = 'x=${normalizedX.toStringAsFixed(2)} > ${(1 - edgeRatio).toStringAsFixed(2)}';
    } else {
      hZone = 1; // 中
      hReason = '${edgeRatio} <= x=${normalizedX.toStringAsFixed(2)} <= ${(1 - edgeRatio).toStringAsFixed(2)}';
    }

    // 判断垂直位置：0=上, 1=中, 2=下
    final int vZone;
    final String vReason;
    if (normalizedY < edgeRatio) {
      vZone = 0; // 上
      vReason = 'y=${normalizedY.toStringAsFixed(2)} < ${edgeRatio}';
    } else if (normalizedY > (1 - edgeRatio)) {
      vZone = 2; // 下
      vReason = 'y=${normalizedY.toStringAsFixed(2)} > ${(1 - edgeRatio).toStringAsFixed(2)}';
    } else {
      vZone = 1; // 中
      vReason = '${edgeRatio} <= y=${normalizedY.toStringAsFixed(2)} <= ${(1 - edgeRatio).toStringAsFixed(2)}';
    }

    debugPrint('[HomeGrid] 🏓 hZone=$hZone (${['左', '中', '右'][hZone]}) ← $hReason');
    debugPrint('[HomeGrid] 🏓 vZone=$vZone (${['上', '中', '下'][vZone]}) ← $vReason');

    // 九宫格映射到方向
    // 中心区域 (hZone=1, vZone=1) 返回 null，表示合并/堆叠操作
    // 边缘区域返回对应方向
    if (hZone == 1 && vZone == 1) {
      // 中心区域：不返回方向，由调用方处理为合并/堆叠
      debugPrint('[HomeGrid] 🎯 Result: CENTER (merge)');
      return null;
    }

    // 根据所在区域选择方向
    _DropDirection? result;
    if (vZone == 0) {
      // 上区域
      result = _DropDirection.top;
    } else if (vZone == 2) {
      // 下区域
      result = _DropDirection.bottom;
    } else if (hZone == 0) {
      // 左区域
      result = _DropDirection.left;
    } else if (hZone == 2) {
      // 右区域
      result = _DropDirection.right;
    }

    if (result != null) {
      debugPrint('[HomeGrid] ✅ Result: $result');
      return result;
    }

    // 备用逻辑：选择最近的边缘
    final double distTop = clampedY;
    final double distBottom = height - clampedY;
    final double distLeft = clampedX;
    final double distRight = width - clampedX;

    final distances = <_DropDirection, double>{
      _DropDirection.top: distTop,
      _DropDirection.bottom: distBottom,
      _DropDirection.left: distLeft,
      _DropDirection.right: distRight,
    };

    final minEntry = distances.entries.reduce((prev, next) {
      return prev.value <= next.value ? prev : next;
    });

    debugPrint('[HomeGrid] ✅ Result (fallback): ${minEntry.key}');
    return minEntry.key;
  }

  void _activateDropZone(_DropRegion zone) {
    final bool hadPreview = _previewDraggingId != null;
    setState(() {
      if (hadPreview) {
        _resetPreviewOrder();
      }
      _hoveredDropZone = zone;
    });
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 1), () {
      _applyPreview(zone);
    });
  }

  void _clearHoveredZone() {
    final bool hadPreview = _previewDraggingId != null;
    setState(() {
      if (hadPreview) {
        _resetPreviewOrder();
      } else {
        _hoveredDropZone = null;
      }
    });
    _previewTimer?.cancel();
    _previewTimer = null;
  }

  int _mapDisplayIndexToActual(int displayIndex, List<String> displayOrder) {
    if (displayIndex >= displayOrder.length) {
      return widget.items.length;
    }
    final referenceId = displayOrder[displayIndex];
    final actualIndex = widget.items.indexWhere((element) => element.id == referenceId);
    if (actualIndex == -1) {
      return widget.items.length;
    }
    return actualIndex;
  }

  void _applyPreview(_DropRegion zone) {
    if (_hoveredDropZone != zone) {
      return;
    }
    final draggedId = _draggingItemId;
    if (draggedId == null) {
      return;
    }

    // 中心区域（direction == null）不应用排序预览，用于合并操作
    if (zone.direction == null) {
      return;
    }

    final currentOrder = _displayOrder.isEmpty
        ? widget.items.map((item) => item.id).toList()
        : List<String>.from(_displayOrder);
    final fromIndex = currentOrder.indexOf(draggedId);
    if (fromIndex == -1) {
      return;
    }

    int displayTargetIndex = zone.index;
    if (zone.direction == _DropDirection.bottom || zone.direction == _DropDirection.right) {
      displayTargetIndex += 1;
    }
    displayTargetIndex = displayTargetIndex.clamp(0, currentOrder.length);
    final actualTargetIndex = _mapDisplayIndexToActual(displayTargetIndex, currentOrder);

    final newOrder = List<String>.from(currentOrder);
    final removed = newOrder.removeAt(fromIndex);
    if (fromIndex < displayTargetIndex) {
      displayTargetIndex -= 1;
    }
    newOrder.insert(displayTargetIndex, removed);

    setState(() {
      _displayOrder
        ..clear()
        ..addAll(newOrder);
      _previewDraggingId = draggedId;
      _pendingTargetIndex = actualTargetIndex;
    });
    _previewTimer = null;
  }

  Future<void> _handleCenterDrop(
    BuildContext context,
    int targetIndex,
    DragTargetDetails<String> details,
  ) async {
    final draggedId = details.data;
    if (draggedId == null) {
      _resetPreviewStateAfterDrop();
      return;
    }

    final orderedItems = _buildOrderedItems();
    if (targetIndex < 0 || targetIndex >= orderedItems.length) {
      _resetPreviewStateAfterDrop();
      return;
    }

    final targetItem = orderedItems[targetIndex];
    if (draggedId == targetItem.id) {
      _resetPreviewStateAfterDrop();
      return;
    }

    final draggedItem = _findItemById(draggedId);

    if (targetItem is HomeFolderItem && widget.onReorder != null) {
      if (draggedItem == null) {
        _resetPreviewStateAfterDrop();
        return;
      }
      final result = await _showDragToFolderDialog(context, draggedItem, targetItem);
      if (result == _DragToFolderAction.replace) {
        final sourceIndex = widget.items.indexWhere((element) => element.id == draggedId);
        if (sourceIndex != -1) {
          widget.onReorder!(sourceIndex, targetIndex);
        }
      } else if (result == _DragToFolderAction.addToFolder) {
        _handleAddToFolder(draggedItem.id, targetItem.id);
      }
      _resetPreviewStateAfterDrop();
      return;
    }

    if (draggedItem != null && widget.onMergeIntoStack != null) {
      final handled = await widget.onMergeIntoStack!(context, targetItem, draggedItem);
      if (handled) {
        _resetPreviewStateAfterDrop();
        return;
      }
    }

    bool handled = false;
    if (draggedItem != null && widget.onReorder != null) {
      final sourceIndex = widget.items.indexWhere((element) => element.id == draggedId);
      if (sourceIndex != -1) {
        final newIndex = _pendingTargetIndex ??
            _mapDisplayIndexToActual(targetIndex, _displayOrder.isEmpty
                ? widget.items.map((item) => item.id).toList()
                : _displayOrder);
        widget.onReorder!(sourceIndex, newIndex);
        handled = true;
      }
    } else if (draggedItem == null &&
        widget.onCrossLayoutDrop != null &&
        widget.layoutId != null) {
      final actualIndex = _pendingTargetIndex ??
          _mapDisplayIndexToActual(targetIndex, _displayOrder.isEmpty
              ? widget.items.map((item) => item.id).toList()
              : _displayOrder);
      handled = await widget.onCrossLayoutDrop!(draggedId, widget.layoutId!, actualIndex);
    }

    _resetPreviewStateAfterDrop();
    if (handled) {
      widget.onDragEnded?.call();
    }
  }

  void _resetPreviewStateAfterDrop() {
    setState(() {
      _hoveringIndex = null;
      _draggingIndex = null;
      _draggingItemId = null;
      _hoveredDropZone = null;
      _resetPreviewOrder();
    });
    _previewTimer?.cancel();
    _previewTimer = null;
  }

  HomeItem? _findItemById(String id) {
    try {
      return widget.items.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Alignment _alignmentForDirection(_DropDirection direction) {
    switch (direction) {
      case _DropDirection.top:
        return Alignment.topCenter;
      case _DropDirection.bottom:
        return Alignment.bottomCenter;
      case _DropDirection.left:
        return Alignment.centerLeft;
      case _DropDirection.right:
        return Alignment.centerRight;
    }
  }

  _PluginCardState _resolvePluginState(BuildContext context, HomeItem item) {
    HomeWidgetItem? widgetItem;
    if (item is HomeWidgetItem) {
      widgetItem = item;
    } else if (item is HomeStackItem && item.children.isNotEmpty) {
      final index = item.activeIndex.clamp(0, item.children.length - 1);
      widgetItem = item.children[index];
    } else {
      return const _PluginCardState(
        isPluginItem: false,
        isDisabled: false,
        displayName: '',
      );
    }

    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget(widgetItem.widgetId);

    if (widgetDef == null) {
      return const _PluginCardState(
        isPluginItem: false,
        isDisabled: false,
        displayName: '',
      );
    }

    final pluginId = widgetDef.pluginId;
    final plugin = globalPluginManager.getPlugin(pluginId);
    final enabledInConfig = globalConfigManager.isPluginEnabled(pluginId);
    final isDisabled = !enabledInConfig;

    final displayName = plugin?.getPluginName(context) ?? widgetDef.name;

    return _PluginCardState(
      isPluginItem: true,
      isDisabled: isDisabled,
      displayName: displayName,
    );
  }

  Widget _wrapWithDisabledOverlay(
    BuildContext context,
    Widget child,
    _PluginCardState state, {
    required bool isInEditMode,
  }) {
    if (!state.isPluginItem || !state.isDisabled) {
      return child;
    }

    final overlayColor = Colors.black.withOpacity(isInEditMode ? 0.2 : 0.4);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, color: Colors.white70, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      state.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'screens_pluginDisabled'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPluginDisabledToast(
    BuildContext context,
    _PluginCardState state,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${state.displayName} ${'screens_pluginDisabled'.tr}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, ) {
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
            'screens_noWidgetsYet'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'screens_clickPlusToAdd'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await _showQuickCreateLayoutDialog(context);
              if (result != null && widget.onQuickCreateLayout != null) {
                widget.onQuickCreateLayout!(result);
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            label: Text('screens_quickCreateLayout'.tr),
          ),
        ],
      ),
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 显示快速创建布局对话框
  Future<Map<String, String>?> _showQuickCreateLayoutDialog(
    BuildContext context,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: 'screens_quickLayout'.tr,
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('screens_quickCreateLayout'.tr),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'screens_layoutName'.tr,
                hintText: 'screens_layoutNameHint'.tr,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('screens_pleaseEnterLayoutName'.tr),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, {'name': name});
                },
                child: Text('screens_create'.tr),
              ),
            ],
          ),
    );

    return result;
  }
}

class _PluginCardState {
  final bool isPluginItem;
  final bool isDisabled;
  final String displayName;

  const _PluginCardState({
    required this.isPluginItem,
    required this.isDisabled,
    required this.displayName,
  });
}

/// 拖拽到文件夹的操作枚举
enum _DropDirection { top, bottom, left, right }

class _DropRegion {
  final int index;
  final _DropDirection? direction; // null 表示中心区域（合并/堆叠）

  const _DropRegion(this.index, this.direction);

  @override
  bool operator ==(Object other) {
    return other is _DropRegion && other.index == index && other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(index, direction);
}

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
    itemName =
        registry.getWidget(draggedItem.widgetId)?.name ??
        'screens_component'.tr;
  } else if (draggedItem is HomeFolderItem) {
    itemName = draggedItem.name;
  } else {
    itemName = 'screens_item'.tr;
  }

  return showDialog<_DragToFolderAction>(
    context: context,
    builder: (context) => AlertDialog(
          title: Text('screens_dragToFolder'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'screens_dragItemToFolder'.trParams({
                  'item': itemName,
                  'folder': targetFolder.name,
                }),
              ),
          const SizedBox(height: 16),
              Text('screens_pleaseSelectAction'.tr),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.cancel),
              child: Text('screens_cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.replace),
              child: Text('screens_replacePosition'.tr),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _DragToFolderAction.addToFolder),
              child: Text('screens_addToFolder'.tr),
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
