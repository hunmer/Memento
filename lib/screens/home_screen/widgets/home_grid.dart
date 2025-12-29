
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'home_card.dart';
import 'layout_type_selector.dart';

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
  final void Function(Map<String, String>)? onQuickCreateLayout;

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
    this.onQuickCreateLayout,
  });

  @override
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> {
  int? _draggingIndex;
  int? _hoveringIndex;
  final String _quickLayoutType = 'empty';

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
      // 处理自定义尺寸
      if (item.size == HomeWidgetSize.custom) {
        // 从 config 中读取自定义宽高
        crossAxisCellCount = item.config['customWidth'] as int? ?? 2;
        mainAxisCellCount = item.config['customHeight'] as int? ?? 2;
      } else {
        crossAxisCellCount = item.size.width;
        mainAxisCellCount = item.size.height;
      }
    } else if (item is HomeFolderItem) {
      // 文件夹固定为 1x1
      crossAxisCellCount = 1;
      mainAxisCellCount = 1;
    }

    final isBeingDragged = _draggingIndex == index;
    final isHovering = _hoveringIndex == index;

    final pluginState = _resolvePluginState(context, item);

    // 如果不是编辑模式，返回普通卡片（包括批量选择模式）
    if (!widget.isEditMode) {
      final isSelected = widget.isBatchMode && widget.selectedItemIds.contains(item.id);
      final bool shouldInterceptTap = pluginState.isPluginItem && pluginState.isDisabled;

      Widget card = HomeCard(
        key: ValueKey(item.id),
        item: item,
        isSelected: isSelected,
        isBatchMode: widget.isBatchMode,
        onTap:
            shouldInterceptTap
                ? () => _showPluginDisabledToast(context, pluginState)
                : widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
        onLongPress: widget.onItemLongPress != null ? () => widget.onItemLongPress!(item) : null,
      );

      card = _wrapWithDisabledOverlay(context, card, pluginState, isInEditMode: false);

      return StaggeredGridTile.count(
        crossAxisCellCount: crossAxisCellCount,
        mainAxisCellCount: mainAxisCellCount,
        child: card,
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
              child: _wrapWithDisabledOverlay(
                context,
                HomeCard(
                  key: ValueKey(item.id),
                  item: item,
                  isSelected: isBeingDragged || isHovering,
                  isEditMode: true,
                  onTap: null,
                  onLongPress: null,
                  dragHandle: dragHandleWidget,
                ),
                pluginState,
                isInEditMode: true,
              ),
            ),
          );
        },
      ),
    );
  }

  _PluginCardState _resolvePluginState(BuildContext context, HomeItem item) {
    if (item is! HomeWidgetItem) {
      return const _PluginCardState(
        isPluginItem: false,
        isDisabled: false,
        displayName: '',
      );
    }

    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget(item.widgetId);

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

    final displayName =
        plugin?.getPluginName(context) ?? widgetDef.name;

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

  /// 显示快速创建布局对话框
  Future<Map<String, String>?> _showQuickCreateLayoutDialog(
    BuildContext context,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: 'screens_quickLayout'.tr,
    );
    String selectedType = _quickLayoutType;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('screens_quickCreateLayout'.tr),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'screens_layoutName'.tr,
                      hintText: 'screens_layoutNameHint'.tr,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('screens_selectLayoutTemplate'.tr),
                  const SizedBox(height: 16),
                  LayoutTypeSelector(
                    initialType: selectedType,
                    onTypeChanged: (type) {
                      selectedType = type;
                    },
                  ),
                ],
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text('screens_pleaseEnterLayoutName'.tr),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, {'name': name, 'type': selectedType});
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
