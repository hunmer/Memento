import 'dart:io';

import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'home_grid.dart';
import 'add_widget_dialog.dart';

/// 文件夹内容对话框
class FolderDialog extends StatefulWidget {
  final HomeFolderItem folder;

  const FolderDialog({
    super.key,
    required this.folder,
  });

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();

  @override
  Widget build(BuildContext context) {    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // 标题栏
            AppBar(
              title: Row(
                children: [
                  Icon(widget.folder.icon, color: widget.folder.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              automaticallyImplyLeading:
                  !(Platform.isAndroid || Platform.isIOS),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddToFolderOptions,
                  tooltip: 'screens_addToFolder'.tr,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editFolder,
                  tooltip: 'screens_editFolder'.tr,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // 文件夹内容网格
            Expanded(
              child: ListenableBuilder(
                listenable: _layoutManager,
                builder: (context, child) {
                  // 重新获取最新的文件夹数据
                  final folder = _layoutManager.findItem(widget.folder.id);
                  if (folder == null || folder is! HomeFolderItem) {
                    return Center(
                      child: Text('screens_folderHasBeenDeleted'.tr),
                    );
                  }

                  if (folder.children.isEmpty) {
                    return _buildEmptyState();
                  }

                  return HomeGrid(
                    items: folder.children,
                    crossAxisCount: 3, // 文件夹内使用 3 列布局
                    onReorder: (oldIndex, newIndex) {
                      _layoutManager.reorderInFolder(
                        folder.id,
                        oldIndex,
                        newIndex,
                      );
                    },
                    onItemLongPress: (item) {
                      _showItemOptions(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加到文件夹选项
  void _showAddToFolderOptions() {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_box),
            title: Text('screens_addWidget'.tr),
            onTap: () {
              Navigator.pop(context);
              _showAddWidgetToFolder();
            },
          ),
          ListTile(
            leading: const Icon(Icons.move_down),
            title: Text('screens_moveFromHomePage'.tr),
            onTap: () {
              Navigator.pop(context);
              _showMoveFromHomeOptions();
            },
          ),
        ],
      ),
    );
  }

  /// 显示添加小组件到文件夹
  void _showAddWidgetToFolder() {
    showDialog(
      context: context,
      builder: (context) => AddWidgetDialog(folderId: widget.folder.id),
    );
  }

  /// 显示从主页移入选项
  void _showMoveFromHomeOptions() {
    // 获取主页上的所有项目（排除当前文件夹）
    final homeItems = _layoutManager.items
        .where((item) => item.id != widget.folder.id)
        .toList();

    if (homeItems.isEmpty) {          Toast.warning('screens_noItemsOnHome'.tr);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _MoveFromHomeDialog(
        items: homeItems,
        folderId: widget.folder.id,
        layoutManager: _layoutManager,
      ),
    );
  }

  /// 编辑文件夹
  void _editFolder() {
    showDialog(
      context: context,
      builder: (context) => _EditFolderDialog(
        folder: widget.folder,
        layoutManager: _layoutManager,
      ),
    );
  }

  /// 显示项目选项
  void _showItemOptions(HomeItem item) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: Text('screens_moveOutOfFolder'.tr),
            onTap: () {
              Navigator.pop(context);
              _layoutManager.removeFromFolder(item.id, widget.folder.id);
              Toast.success('screens_movedToHomePage'.tr);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteItem(item);
            },
          ),
        ],
      ),
    );
  }

  /// 确认删除项目
  void _confirmDeleteItem(HomeItem item) {    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_confirmDelete'.tr),
        content: Text('screens_confirmDeleteThisItem'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('screens_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 从文件夹的 children 中删除
              final folder = _layoutManager.findItem(widget.folder.id) as HomeFolderItem;
              final updatedFolder = folder.copyWith(
                children: folder.children.where((c) => c.id != item.id).toList(),
              );
              _layoutManager.updateItem(widget.folder.id, updatedFolder);
                          Toast.success('screens_deleteSuccess'.tr);
            },
            child: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'screens_folderIsEmpty'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'screens_clickToAddContent'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// 从主页移入对话框
class _MoveFromHomeDialog extends StatefulWidget {
  final List<HomeItem> items;
  final String folderId;
  final HomeLayoutManager layoutManager;

  const _MoveFromHomeDialog({
    required this.items,
    required this.folderId,
    required this.layoutManager,
  });

  @override
  State<_MoveFromHomeDialog> createState() => _MoveFromHomeDialogState();
}

class _MoveFromHomeDialogState extends State<_MoveFromHomeDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {    return AlertDialog(
      title: Text('screens_moveFromHomePage'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'screens_selectItemsToMoveToFolder'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = _selectedIds.contains(item.id);

                  Widget? leadingIcon;
                  String displayName;

                  if (item is HomeWidgetItem) {
                    final registry = HomeWidgetRegistry();
                    final widget = registry.getWidget(item.widgetId);
                    if (widget != null) {
                      leadingIcon = Icon(widget.icon, color: widget.color, size: 20);
                      displayName = widget.name;
                    } else {
                      displayName = item.widgetId;
                    }
                  } else if (item is HomeFolderItem) {
                    leadingIcon = Icon(item.icon, color: item.color, size: 20);
                    displayName = item.name;
                  } else {
                    displayName = 'Unknown';
                  }

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(item.id);
                        } else {
                          _selectedIds.remove(item.id);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        if (leadingIcon != null) leadingIcon,
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  _moveSelectedItems();
                  Navigator.pop(context);
                },
          child: Text('screens_moveIn'.trParams({'count': _selectedIds.length.toString()})),
        ),
      ],
    );
  }

  /// 移动选中的项目
  void _moveSelectedItems() {    for (final itemId in _selectedIds) {
      widget.layoutManager.moveToFolder(itemId, widget.folderId);
    }

      Toast.success('screens_itemsMovedToFolder'.trParams({'count': _selectedIds.length.toString()}));
  }
}

/// 编辑文件夹对话框
class _EditFolderDialog extends StatefulWidget {
  final HomeFolderItem folder;
  final HomeLayoutManager layoutManager;

  const _EditFolderDialog({
    required this.folder,
    required this.layoutManager,
  });

  @override
  State<_EditFolderDialog> createState() => _EditFolderDialogState();
}

class _EditFolderDialogState extends State<_EditFolderDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  // 常用图标列表
  static const List<IconData> _commonIcons = [
    Icons.folder,
    Icons.folder_special,
    Icons.work,
    Icons.school,
    Icons.home,
    Icons.favorite,
    Icons.star,
    Icons.bookmark,
    Icons.category,
    Icons.dashboard,
    Icons.widgets,
    Icons.apps,
  ];

  // 常用颜色列表
  static const List<Color> _commonColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _selectedIcon = widget.folder.icon;
    _selectedColor = widget.folder.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    return AlertDialog(
      title: Text('screens_editFolder'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文件夹名称
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'screens_folderName'.tr,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),

              // 图标选择
              Text(
                'screens_selectIcon'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonIcons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? _selectedColor
                            : Theme.of(context).iconTheme.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 颜色选择
              Text(
                'screens_selectColor'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonColors.map((color) {
                  final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('screens_cancel'.tr),
        ),
        FilledButton(
          onPressed: _saveFolderChanges,
          child: Text('screens_save'.tr),
        ),
      ],
    );
  }

  /// 保存文件夹修改
  void _saveFolderChanges() {
    final newName = _nameController.text.trim();    if (newName.isEmpty) {
          Toast.error('screens_pleaseEnterFolderName'.tr);
      return;
    }

    // 创建更新后的文件夹
    final updatedFolder = widget.folder.copyWith(
      name: newName,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    // 更新文件夹
    widget.layoutManager.updateItem(widget.folder.id, updatedFolder);

    Navigator.pop(context);
    Toast.success('screens_folderUpdated'.tr);
  }
}
