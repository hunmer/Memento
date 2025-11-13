import 'package:flutter/material.dart';
import '../models/home_folder_item.dart';
import '../managers/home_layout_manager.dart';
import '../models/home_item.dart';
import 'home_grid.dart';
import 'add_widget_dialog.dart';

/// 文件夹内容对话框
class FolderDialog extends StatefulWidget {
  final HomeFolderItem folder;

  const FolderDialog({
    Key? key,
    required this.folder,
  }) : super(key: key);

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddToFolderOptions,
                  tooltip: '添加到文件夹',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editFolder,
                  tooltip: '编辑文件夹',
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
                    return const Center(
                      child: Text('文件夹已被删除'),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('添加小组件'),
              onTap: () {
                Navigator.pop(context);
                _showAddWidgetToFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.move_down),
              title: const Text('从主页移入'),
              onTap: () {
                Navigator.pop(context);
                _showMoveFromHomeOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加小组件到文件夹
  void _showAddWidgetToFolder() {
    // TODO: 实现添加小组件到文件夹
    showDialog(
      context: context,
      builder: (context) => const AddWidgetDialog(),
    ).then((_) {
      // 添加后需要将小组件移到文件夹
      // 暂时简化处理
    });
  }

  /// 显示从主页移入选项
  void _showMoveFromHomeOptions() {
    // TODO: 实现从主页选择项目移入文件夹
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能开发中...')),
    );
  }

  /// 编辑文件夹
  void _editFolder() {
    // TODO: 实现编辑文件夹
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑文件夹功能开发中...')),
    );
  }

  /// 显示项目选项
  void _showItemOptions(HomeItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('移出文件夹'),
              onTap: () {
                Navigator.pop(context);
                _layoutManager.removeFromFolder(item.id, widget.folder.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已移出到主页')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteItem(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 确认删除项目
  void _confirmDeleteItem(HomeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个项目吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
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
            '文件夹是空的',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方 + 按钮添加内容',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}
