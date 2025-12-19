import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:Memento/plugins/notes/models/folder.dart';

/// 文件夹树节点，用于 animated_tree_view 展示
class FolderTreeNode extends TreeNode<Folder> {
  FolderTreeNode({
    required Folder folder,
    List<FolderTreeNode>? children,
  }) : super(
          key: folder.id,
          data: folder,
        ) {
    if (children != null) {
      addAll(children);
    }
  }

  /// 获取文件夹数据
  Folder get folder => data!;

  /// 从文件夹列表构建树形结构
  static FolderTreeNode buildTree(
    Folder folder,
    Map<String, Folder> allFolders,
  ) {
    // 找到当前文件夹的所有子文件夹
    final children = allFolders.values
        .where((f) => f.parentId == folder.id)
        .map((childFolder) => buildTree(childFolder, allFolders))
        .toList();

    return FolderTreeNode(
      folder: folder,
      children: children,
    );
  }
}
