import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/folder_tree_node.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// 文件夹选择底部抽屉
class FolderSelectionSheet extends StatefulWidget {
  /// 根文件夹树节点
  final FolderTreeNode rootNode;

  /// 当前笔记（用于高亮当前所在文件夹）
  final Note? note;

  /// 父文件夹（如果指定，则只显示该文件夹的子文件夹）
  final Folder? parentFolder;

  const FolderSelectionSheet({
    super.key,
    required this.rootNode,
    this.note,
    this.parentFolder,
  });

  /// 显示文件夹选择底部抽屉
  static Future<Folder?> show({
    required BuildContext context,
    required FolderTreeNode rootNode,
    Note? note,
    Folder? parentFolder,
  }) async {
    return SmoothBottomSheet.show<Folder>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FolderSelectionSheet(
        rootNode: rootNode,
        note: note,
        parentFolder: parentFolder,
      ),
    );
  }

  @override
  State<FolderSelectionSheet> createState() => _FolderSelectionSheetState();
}

class _FolderSelectionSheetState extends State<FolderSelectionSheet> {
  String? _currentFolderId;
  late FolderTreeNode _displayRootNode;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.note?.folderId;

    // 如果指定了父文件夹，则只显示该文件夹的子树
    if (widget.parentFolder != null) {
      _displayRootNode =
          _findNodeById(widget.rootNode, widget.parentFolder!.id) ??
              widget.rootNode;
    } else {
      _displayRootNode = widget.rootNode;
    }
  }

  /// 根据 ID 查找节点
  FolderTreeNode? _findNodeById(dynamic node, String id) {
    if (node is TreeNode && node.key == id) {
      return node as FolderTreeNode;
    }

    if (node is TreeNode) {
      final children = node.childrenAsList;
      for (var child in children) {
        final found = _findNodeById(child, id);
        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题栏
        _buildHeader(),

        const Divider(height: 1),

        // 文件夹树
        Expanded(
          child: TreeView.simple(
            tree: _displayRootNode,
            showRootNode: _displayRootNode.key != 'root',
            expansionIndicatorBuilder: (context, node) {
              return ChevronIndicator.rightDown(
                tree: node,
                color: Theme.of(context).iconTheme.color,
                padding: const EdgeInsets.all(8),
              );
            },
            indentation: const Indentation(width: 24),
            // 树准备就绪时展开所有节点
            onTreeReady: (controller) {
              controller.expandAllChildren(_displayRootNode);
            },
            builder: (context, node) {
              final folderNode = node as FolderTreeNode;
              return _buildFolderItem(
                folderNode.folder,
                folderNode.childrenAsList.isNotEmpty,
              );
            },
          ),
        ),

        // 底部操作栏
        _buildBottomActions(),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    // 根据不同场景显示不同的标题
    String title;
    if (widget.parentFolder != null) {
      title = 'notes_selectSubfolder'.tr;
    } else if (widget.note != null) {
      title = 'notes_moveTo'.tr;
    } else {
      title = 'notes_selectFolder'.tr;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 构建文件夹项
  Widget _buildFolderItem(Folder folder, bool hasChildren) {
    final isCurrentFolder = folder.id == _currentFolderId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentFolder
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onFolderTap(folder),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 文件夹图标
                Icon(
                  folder.icon,
                  color: folder.color,
                  size: 24,
                ),
                const SizedBox(width: 16),
                // 文件夹名称
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isCurrentFolder ? FontWeight.bold : FontWeight.normal,
                      color:
                          isCurrentFolder ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
                // 当前文件夹标记
                if (isCurrentFolder)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActions() {
    // 检查是否可以选择父文件夹
    final parentFolder = widget.parentFolder;
    final canSelectParent =
        parentFolder != null && parentFolder.id != _currentFolderId;

    // 获取根文件夹
    final rootFolder = widget.rootNode.folder;
    final canSelectRoot = rootFolder.id != _currentFolderId && rootFolder.id == 'root';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 取消按钮
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
            ),

            // 选择根目录按钮
            if (canSelectRoot) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, rootFolder),
                  icon: const Icon(Icons.home),
                  label: Text('notes_selectRoot'.tr),
                ),
              ),
            ]
            // 选择当前文件夹按钮（用于子文件夹场景）
            else if (canSelectParent) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, parentFolder),
                  icon: const Icon(Icons.check),
                  label: Text('notes_selectCurrentFolder'.tr),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 文件夹点击处理
  void _onFolderTap(Folder folder) {
    // 如果是当前文件夹，不做任何操作
    if (folder.id == _currentFolderId) {
      return;
    }

    // 选择文件夹并关闭抽屉
    Navigator.pop(context, folder);
  }
}
